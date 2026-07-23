---@alias twee.Symbol.Type "widget"|"variable"|"passage"|"function"|"keyword"

---@class twee.Symbol
---@field uri? string
---@field line? number
---@field documentation? string
---@field deprecated? boolean
---@field deprecated_suggestions? table
---@field closed? boolean For widgets. Defines if the widget needs to close with <</widgetName>>
---@field insert_text? string
---@field parameters? string[] For functions. A table containing all parameters of a function
---@field next? table For variables. Stores all attributes of a variable
---@field value? any For variables. Stores the value of the variable

---@class twee.SymbolsTbl.Symbols
---@field widget table<string, twee.Symbol>
---@field variable table<string, twee.Symbol>
---@field passage table<string, twee.Symbol>
---@field function table<string, twee.Symbol>
---@field keyword table<string, twee.Symbol>

---@class twee.SymbolsTbl
---@field buf_symbols twee.SymbolsTbl.Symbols
---@field global_symbols twee.SymbolsTbl.Symbols

---@class twee.ContentTbl
---@field twee_content table<string, table>
---@field js_content table<string, table>

local M = {}

--- Add a type of symbol to a CompletionItem[] table.
---@param symbols twee.SymbolsTbl Table of symbols
---@param type twee.Symbol.Type|"chain" Type of symbol to add
---@param completion_table table Completion table to extend
function M.add_symbols_to_completion_table(symbols, type, completion_table)
  local added = {}

  for _, symbol_tbl in pairs(symbols) do
    ---@type twee.SymbolsTbl.Symbols
    symbol_tbl = symbol_tbl

    if type == "chain" then
      local line = vim.fn.getline(".")
      local var

      for str in string.gmatch(line, "$([a-zA-Z_.]+)") do
        var = str
      end

      var = var:gsub("$", ""):gsub("%.$", "")
      local var_tbl = vim.split(var, "%.")

      local item = symbol_tbl["variable"][var_tbl[1]]

      if item == nil then
        goto continue
      end

      local next_var = symbol_tbl["variable"][var_tbl[1]].next

      if next_var == nil then
        goto continue
      end

      if #var_tbl > 1 then
        for i = 2, #var_tbl do
          next_var = next_var[var_tbl[i]]
        end
      end

      for k, _ in pairs(next_var) do
        if added[k] then
          goto continue
        end

        vim.list_extend(completion_table, {
          {
            label = k,
            kind = vim.lsp.protocol.CompletionItemKind.Variable,
          },
        })

        added[k] = true
      end
      goto continue
    end

    if type == "variable" then
      for item, sym_tbl in pairs(symbol_tbl["variable"]) do
        ---@type twee.Symbol
        sym_tbl = sym_tbl

        if added[item] then
          goto continue
        end

        vim.list_extend(completion_table, {
          {
            label = item,
            detail = "$" .. item,
            kind = vim.lsp.protocol.CompletionItemKind.Variable,
            documentation = sym_tbl.value,
          },
        })

        added[item] = true
        ::continue::
      end
    elseif type == "widget" then
      for item, sym_tbl in pairs(symbol_tbl["widget"]) do
        ---@type twee.Symbol
        sym_tbl = sym_tbl

        if added[item] then
          goto continue
        end

        local tbl = {
          label = item,
          detail = "<<" .. item .. ">>",
          insertText = "<<" .. item .. ">>",
        }

        if sym_tbl.closed == true then
          tbl["detail"] = "<<" .. item .. ">><</" .. item .. ">>"
          tbl["insertText"] = "<<" .. item .. ">><</" .. item .. ">>"
        end

        if sym_tbl.documentation ~= nil then
          tbl["documentation"] = sym_tbl.documentation
        end

        if sym_tbl.deprecated == true then
          tbl["tags"] = { vim.lsp.protocol.CompletionTag.Deprecated }
        end

        if sym_tbl.deprecated_suggestions ~= nil then
          tbl["documentation"] = (tbl["documentation"] or "")
            .. "\n\nDeprecated.\n\n"
            .. "Use: \n- "
            .. table.concat(sym_tbl.deprecated_suggestions, "\n- ")
        end

        if sym_tbl.insert_text ~= nil then
          tbl["insertText"] = sym_tbl.insert_text
        end

        vim.list_extend(completion_table, { tbl })

        added[item] = true
        ::continue::
      end
    elseif type == "passage" then
      for item, sym_tbl in pairs(symbol_tbl["passage"]) do
        ---@type twee.Symbol
        sym_tbl = sym_tbl

        if added[item] then
          goto continue
        end

        vim.list_extend(completion_table, {
          {
            label = item,
            insertText = ":: " .. item,
          },
        })

        added[item] = true
        ::continue::
      end
    elseif type == "function" then
      for item, sym_tbl in pairs(symbol_tbl["function"]) do
        ---@type twee.Symbol
        sym_tbl = sym_tbl

        if added[item] then
          goto continue
        end

        local tbl = {
          label = item,
          detail = item .. "()",
          kind = vim.lsp.protocol.CompletionItemKind.Function,
          insertText = item .. "()",
        }

        if sym_tbl.parameters ~= nil then
          tbl["detail"] = item .. "(" .. table.concat(sym_tbl.parameters, ", ") .. ")"
        end

        if sym_tbl.documentation ~= nil then
          tbl["documentation"] = sym_tbl.documentation
        end

        vim.list_extend(completion_table, { tbl })

        added[item] = true
        ::continue::
      end
    elseif type == "keyword" then
      for item, sym_tbl in pairs(symbol_tbl["keyword"]) do
        ---@type twee.Symbol
        sym_tbl = sym_tbl

        if added[item] then
          goto continue
        end

        vim.list_extend(completion_table, {
          {
            label = item,
            kind = vim.lsp.protocol.CompletionItemKind.Keyword,
          },
        })

        added[item] = true
        ::continue::
      end
    end

    ::continue::
  end
end

--- Search for a pattern in a content and return a Location[] table of all results.
---@param content twee.ContentTbl Content to search
---@param pattern string Pattern to search
---@param opts? { only_current_buffer: boolean }
---@return lsp.Location[]|nil
function M.find_location(content, pattern, opts)
  opts = opts or {}
  opts.only_current_buffer = opts.only_current_buffer or false

  local location = {}

  if opts.only_current_buffer then
    content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    for i, line in ipairs(content) do
      local start = 0

      for _ in string.gmatch(line, pattern) do
        local char_start, char_end = string.find(line, pattern, start)

        ---@cast char_start integer
        ---@cast char_end integer

        start = char_end + 1

        vim.list_extend(location, {
          {
            range = M.make_range(i - 1, char_start - 1, i - 1, char_end),
          },
        })
      end
    end

    if #location == 0 then
      return nil
    end

    return location
  end

  for uri, file_content in pairs(content) do
    for i, line in ipairs(file_content) do
      local start = 0

      for _ in string.gmatch(line, pattern) do
        local char_start, char_end = string.find(line, pattern, start)

        ---@cast char_start integer
        ---@cast char_end integer

        start = char_end + 1

        vim.list_extend(location, {
          {
            uri = uri,
            range = M.make_range(i - 1, char_start - 1, i - 1, char_end),
          },
        })
      end
    end
  end

  if #location == 0 then
    return nil
  end

  return location
end

--- Generates a random ifid
---@return string ifid
function M.generate_ifid()
  local ifid_tbl = {}

  for i = 1, 20 do
    local rand_tbl = {}

    for _ = 1, 100 do
      table.insert(rand_tbl, string.char(math.random(48, 57)))
      table.insert(rand_tbl, string.char(math.random(65, 70)))
    end

    local choice1 = math.random(#rand_tbl)
    local choice2 = math.random(#rand_tbl)

    local hex = rand_tbl[choice1] .. rand_tbl[choice2]

    if vim.list_contains({ 5, 8, 11, 14 }, i) then
      table.insert(ifid_tbl, "-")
    elseif i == 9 then
      table.insert(ifid_tbl, "4" .. rand_tbl[choice2])
    elseif i == 12 then
      local choice_tbl = { "8", "9", "A", "B" }

      table.insert(ifid_tbl, choice_tbl[math.random(#choice_tbl)] .. rand_tbl[choice2])
    else
      table.insert(ifid_tbl, hex)
    end
  end

  local ifid = '"' .. table.concat(ifid_tbl, "") .. '"'

  return ifid
end

--- Returns the string under the cursor position
---@return string str
function M.get_current_string()
  local current_char = vim.api.nvim_win_get_cursor(0)[2]
  local current_line_content = vim.api.nvim_get_current_line()
  local repl_list = { "-", ".", "?", "*", "+", "[", "]", "{", "}", "(", ")" }

  for str in string.gmatch(current_line_content, '".-"') do
    for _, item in ipairs(repl_list) do
      local pattern = "%" .. item
      local repl = "%%" .. item

      str = str:gsub(pattern, repl)
    end

    local str_start, str_end = string.find(current_line_content, str)

    if current_char >= str_start - 1 and current_char <= str_end - 1 then
      return str
    end
  end

  return ""
end

---@class twee.get_pos_hl_group.Opts
---@field blacklist table Defines what highlight groups to ignore. See :help group-name.

--- Get the highlight group a position.
---
--- Example:
---
--- ```lua
--- -- Inside a function
--- local hl_group = get_pos_hl_group(0, nil, nil, { blacklist = { "Comment", "Delimiter", "Operator" } })
---
--- if hl_group == nil then
---   return nil
--- end
--- ```
---@param bufnr? integer Defaults to the current buffer
---@param row? integer row to get, 0-based. Defaults to the row of the current cursor
---@param col? integer col to get, 0-based. Defaults to the col of the current cursor
---@param opts? twee.get_pos_hl_group.Opts A table of options
---@return string|nil hl_group # The highlight group name. See :help group-name.
function M.get_pos_hl_group(bufnr, row, col, opts)
  bufnr = bufnr or 0

  if row == nil or col == nil then
    local win = bufnr == 0 and vim.api.nvim_get_current_win() or vim.fn.bufwinid(bufnr)
    if win == -1 then
      error("row/col is required for buffers not visible in a window")
    end
    local cursor = vim.api.nvim_win_get_cursor(win)
    row, col = cursor[1] - 1, cursor[2]
  end

  opts = opts or {}

  opts.blacklist = opts.blacklist or {}

  if vim.inspect_pos(bufnr, row, col)["syntax"][1] == nil then
    return nil
  end

  local hl_group = vim.inspect_pos(bufnr, row, col)["syntax"][1]["hl_group"]

  if vim.list_contains(opts.blacklist, hl_group) then
    return nil
  end

  return hl_group
end

---@param content twee.ContentTbl Twee content to search
---@param symbols twee.SymbolsTbl
function M.get_story_data(content, symbols)
  local story_data_symbol = M.get_symbol(symbols, "StoryData")

  if story_data_symbol == nil then
    return
  end

  local story_data_content = content[story_data_symbol.uri]
  local story_data_tbl = vim.list_slice(story_data_content, story_data_symbol.line + 1, #story_data_content)

  for i, line in ipairs(story_data_tbl) do
    if string.match(line, "::") then
      story_data_tbl = vim.list_slice(story_data_tbl, 1, i - 1)
      break
    end
  end

  for i = #story_data_tbl, 1, -1 do
    if story_data_tbl[i] == "}" then
      _G.story_data = vim.list_slice(story_data_tbl, 1, i)
    end
  end

  local story_data_json = table.concat(story_data_tbl)
  local ok, story_data = pcall(vim.json.decode, story_data_json)

  if not ok then
    _G.story_data_uri = story_data_symbol.uri
    _G.story_data_line = story_data_symbol.line
    _G.story_data_invalid_json = true
    return
  end

  _G.story_data_invalid_json = false

  vim.g.twee_story_data_start = story_data.start or "Start"
end

--- Searchs for a symbol in a table and returns it.
---@param symbols twee.SymbolsTbl
---@param name string Name of symbol
---@return twee.Symbol|nil
function M.get_symbol(symbols, name)
  for _, symbol_tbl in pairs(symbols) do
    for _, syms in pairs(symbol_tbl) do
      for sym_name, sym_tbl in pairs(syms) do
        if sym_name == name then
          return sym_tbl
        end
      end
    end
  end

  return nil
end

--- Makes a Range table
---
--- Example:
---
--- ```lua
--- local diagnostic = {
---   range = make_range(5, 23, 6, 0),
---   message = "Something is wrong"
--- }
--- ```
---@param start_line integer Line position in a document (zero-based)
---@param start_character integer Character offset on a line in a document (zero-based)
---@param end_line integer Line position in a document (zero-based)
---@param end_character integer Character offset on a line in a document (zero-based)
---@return lsp.Range
function M.make_range(start_line, start_character, end_line, end_character)
  local range = {
    start = {
      line = start_line,
      character = start_character,
    },
    ["end"] = {
      line = end_line,
      character = end_character,
    },
  }

  return range
end

--- Makes a textEdit range table
---
--- Example:
---
--- ```lua
--- local completion = {
---   {
---     label = "br",
---     kind = vim.lsp.protocol.CompletionItemKind.Snippet,
---     textEdit = {
---       newText = "<br>"
---       range = make_textEdit_range("br")
---     }
---   }
--- }
--- ```
---@param label string
---@return lsp.Range
function M.make_textEdit_range(label)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local line = vim.fn.getline(".")
  local char_col = col

  for text_len = label:len(), 1, -1 do
    local match = string.sub(line, math.max(col - (text_len - 1), 0), col):lower()

    local label_int = 0

    for _, num in ipairs({ string.byte(label, 1, -1) }) do
      label_int = label_int + num
    end

    local match_int = 0

    for _, num in ipairs({ string.byte(match, 1, -1) }) do
      -- Prevents textEdit from replacing the wrong characters
      if vim.list_contains({ string.byte('".$+-/:<>=[]{}', 1, -1) }, num) then
        match_int = match_int + label_int
      end

      match_int = match_int + num
    end

    if label_int >= match_int then
      char_col = math.max(char_col - text_len, 0)
      break
    end
  end

  return M.make_range(row, char_col, row, col)
end

--- Parses a YML value
local function parse_value(value)
  value = vim.trim(value)

  if value == "null" or value == "~" or value == "" then
    return nil
  end

  if value == "true" or value == "yes" or value == "on" then
    return true
  end

  if value == "false" or value == "no" or value == "off" then
    return false
  end

  local num = tonumber(value)
  if num then
    return num
  end

  if value:match('^".*"$') or value:match("^'.*'$") then
    return value:sub(2, -2)
  end

  return value
end

--- Parse YAML string
---@param yaml string The YAML to parse
---@return table tbl The parsed YAML as a Lua table
function M.parse_yml(yaml)
  yaml = yaml or {}

  local lines = {}
  for line in string.gmatch(yaml, "[^\r\n]+") do
    table.insert(lines, line)
  end

  local tbl = {}
  local stack = { { data = tbl, indent = -1 } }
  local i = 1

  while i <= #lines do
    local line = lines[i]
    local indent = #line:match("^(%s*)")
    line = vim.trim(line)

    if line == "" or line:match("^#") then
      i = i + 1
      goto continue
    end

    while #stack > 1 and indent <= stack[#stack].indent do
      table.remove(stack)
    end

    local current = stack[#stack].data

    if line:match("^%- ") then
      local item = line:sub(3)

      if item:match(":") == nil then
        table.insert(current, parse_value(item))
        i = i + 1
        goto continue
      end

      local new_obj = {}
      table.insert(current, new_obj)
      local key, val = item:match("^([^:]+):%s*(.*)$")

      if key == nil then
        i = i + 1
        goto continue
      end

      key = vim.trim(key)
      new_obj[key] = parse_value(val)
      table.insert(stack, { data = new_obj, indent = indent })
    elseif line:match(":") then
      local key, value = line:match("^([^:]+):%s*(.*)$")

      if key == nil then
        i = i + 1
        goto continue
      end

      key = vim.trim(key)
      value = vim.trim(value or "")

      if value == "" or value:match("^#") then
        if i >= #lines then
          current[key] = nil
          i = i + 1
          goto continue
        end

        local next_line = lines[i + 1]
        local next_indent = #next_line:match("^(%s*)")

        if next_indent <= indent then
          current[key] = nil
          i = i + 1
          goto continue
        end

        current[key] = {}
        table.insert(stack, { data = current[key], indent = indent })
      elseif value == "|-" or value == ">" then
        local str_lines = {}
        i = i + 1

        while i <= #lines do
          local next_line = lines[i]
          local next_indent = #next_line:match("^(%s*)")

          if next_indent <= indent then
            break
          end

          table.insert(str_lines, next_line:sub(indent + 3))
          i = i + 1
        end

        current[key] = table.concat(str_lines, "\n")
        goto continue
      else
        current[key] = parse_value(value)
      end
    end

    i = i + 1
    ::continue::
  end

  return tbl
end

return M
