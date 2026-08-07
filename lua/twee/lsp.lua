local files = require("twee.files")
local utils = require("twee.utils")

local M = {}

local symbols = {}

local files_content = {
  twee_content = {},
  js_content = {},
}

local methods = {}

---@param params lsp.InitializeParams
---@param callback function
methods["initialize"] = function(params, callback)
  return callback(nil, {
    capabilities = {
      codeActionProvider = true,
      definitionProvider = true,
      documentHighlightProvider = true,
      hoverProvider = true,
      referencesProvider = true,
      textDocumentSync = vim.lsp.protocol.TextDocumentSyncKind.Full,
      completionProvider = {
        triggerCharacters = { ":", "<", "$", "." },
      },
    },
  })
end

---@param callback function
methods["shutdown"] = function(_, callback)
  return callback(nil, nil)
end

---@param params lsp.CodeActionParams
methods["textDocument/codeAction"] = function(params, callback)
  local code_action = {}

  local uri = vim.uri_from_bufnr(0)

  local diagnostics = vim.diagnostic.get(0, {
    lnum = params.range.start.line,
  })

  for _, tbl in ipairs(diagnostics) do
    if tbl.code == "twee-widget-storytitle-missing" then
      vim.list_extend(code_action, {
        {
          title = "add story title",
          edit = {
            changes = {
              [uri] = {
                {
                  range = utils.make_range(0, 0, 0, 0),
                  newText = ":: StoryTitle\nSample Text\n\n",
                },
              },
            },
          },
        },
      })
    elseif tbl.code == "twee-widget-storydata-missing" then
      vim.list_extend(code_action, {
        {
          title = "add story data",
          edit = {
            changes = {
              [uri] = {
                {
                  range = utils.make_range(0, 0, 0, 0),
                  newText = ':: StoryData\n{\n\t"ifid": ' .. utils.generate_ifid() .. "\n}\n\n",
                },
              },
            },
          },
        },
      })
    elseif tbl.code == "twee-widget-start-missing" then
      vim.list_extend(code_action, {
        {
          title = "add start",
          edit = {
            changes = {
              [uri] = {
                {
                  range = utils.make_range(0, 0, 0, 0),
                  newText = ":: Start\nSample Text\n\n",
                },
              },
            },
          },
        },
      })
    end
  end

  return callback(nil, code_action)
end

---@param params lsp.CompletionParams
---@param callback function
methods["textDocument/completion"] = function(params, callback)
  local hl_group = utils.get_pos_hl_group() or {}

  if vim.list_contains(hl_group, "Comment") then
    return callback(nil, nil)
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local line = vim.fn.getline(".")

  local trigger_character = params.context.triggerCharacter

  ---@type lsp.CompletionItem[]
  local completion = {}

  if
    string.sub(line, math.max(col - 2, 0)) == "<<"
    or vim.list_contains(utils.get_pos_hl_group(0, row, col - 1) or {}, "Conditional")
  then
    utils.add_symbols_to_completion_table(symbols, "widget", completion)
  elseif string.sub(line, math.max(col, 0), col) == "." then
    if vim.list_contains(utils.get_pos_hl_group(0, row, col - 1) or {}, "Identifier") then
      utils.add_symbols_to_completion_table(symbols, "chain", completion)
    end
  elseif trigger_character == "$" or vim.list_contains(utils.get_pos_hl_group(0, row, col - 1) or {}, "Identifier") then
    utils.add_symbols_to_completion_table(symbols, "variable", completion)
  elseif trigger_character == "<" then
    completion = {
      {
        label = "br",
        insertText = "<br>",
      },
      {
        label = "span",
        insertText = "<span></span>",
      },
      {
        label = "div",
        insertText = "<div></div>",
      },
    }
  else
    local items = {
      {
        label = "passage header",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = ":: $0",
        insertText = ":: $0",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "StoryData",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        insertText = ':: StoryData\n{\n\t"ifid": ' .. utils.generate_ifid() .. "\n}\n\n",
      },
      utils.make_snippet("StoryTitle", ":: StoryTitle\n${0:Sample Text}\n"),
      utils.make_snippet("Start", ":: Start\n${0:Sample Text}\n"),
      utils.make_snippet("capture", "<<capture $1>>\n\t$0\n<</capture>>"),
      utils.make_snippet("set"),
      {
        label = "set ... to",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<set $1 to $0>>",
        insertText = "<<set $1 to $0>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      utils.make_snippet("unset"),
      utils.make_snippet("run"),
      utils.make_snippet("script", "<<script ${1|JavaScript,TwineScript|}>>\n\t$0\n<</script>>"),
      utils.make_snippet("equal", "<<= $0>>"),
      utils.make_snippet("minus", "<<- $0>>"),
      utils.make_snippet("do", "<<do>>\n\t$0\n<</do>>"),
      utils.make_snippet("include"),
      utils.make_snippet("nobr", "<<nobr>>\n\t$0\n<</nobr>>"),
      utils.make_snippet("print"),
      utils.make_snippet("redo"),
      utils.make_snippet("silent", "<<silent>>\n\t$0\n<</silent>>"),
      utils.make_snippet("type", "<<type $1>>\n\t$0\n<</type>>"),
      utils.make_snippet("if", "<<if $1>>\n\t$0\n<</if>>"),
      utils.make_snippet("elseif"),
      utils.make_snippet("else", nil, { has_tab_stop = false }),
      utils.make_snippet("for", "<<for $1>>\n\t$0\n<</for>>"),
      utils.make_snippet("fori", "<<for ${1:_i} to 0; ${2:_i} lt ${3:x}; ${4:_i}++>>\n\t$0\n<</for>>"),
      utils.make_snippet("break", nil, { has_tab_stop = false }),
      utils.make_snippet("continue", nil, { has_tab_stop = false }),
      utils.make_snippet(
        "switch",
        "<<switch ${1:expr}>>\n\t<<case ${2:valueList}>>\n\t\t$3\n\t<<default>>\n\t\t$0\n<</switch>>"
      ),
      utils.make_snippet("button", "<<button $1>>\n\t$0\n<</button>>"),
      utils.make_snippet("checkbox"),
      utils.make_snippet("cycle", "<<cycle $1>>\n\t<<option $2>>\n\t<<option $3>>\n\t$0\n<</cycle>>"),
      utils.make_snippet("link", "<<link $1>>\n\t$0\n<</link>>"),
      utils.make_snippet("linkappend", "<<linkappend $1>>\n\t$0\n<</linkappend>>"),
      utils.make_snippet("linkprepend", "<<linkprepend $1>>\n\t$0\n<</linkprepend>>"),
      utils.make_snippet("linkreplace", "<<linkreplace $1>>\n\t$0\n<</linkreplace>>"),
      utils.make_snippet("listbox", "<<listbox $1>>\n\t<<option $2>>\n\t<<option $3>>\n\t$0\n<</listbox>>"),
      utils.make_snippet("numberbox"),
      utils.make_snippet("radiobutton"),
      utils.make_snippet("textarea"),
      utils.make_snippet("textbox"),
      utils.make_snippet("back"),
      utils.make_snippet("return"),
      utils.make_snippet("addclass"),
      utils.make_snippet("append", "<<append $1>>\n\t$0\n<</append>>"),
      utils.make_snippet("copy"),
      utils.make_snippet("prepend", "<<prepend $1>>\n\t$0\n<</prepend>>"),
      utils.make_snippet("remove"),
      utils.make_snippet("removeclass"),
      utils.make_snippet("replace", "<<replace $1>>\n\t$0\n<</replace>>"),
      utils.make_snippet("toggleclass"),
      utils.make_snippet("audio"),
      utils.make_snippet("cacheaudio"),
      utils.make_snippet(
        "createaudiogroup",
        "<<createaudiogroup $1>>\n\t<<track $2>>\n\t<<track $3>>\n\t$0\n<</createaudiogroup>>"
      ),
      utils.make_snippet(
        "createplaylist",
        "<<createplaylist $1>>\n\t<<track $2>>\n\t<<track $3>>\n\t$0\n<</createplaylist>>"
      ),
      utils.make_snippet("masteraudio"),
      utils.make_snippet("playlist"),
      utils.make_snippet("removeaudiogroup"),
      utils.make_snippet("removeplaylist"),
      utils.make_snippet("waitforaudio", nil, { has_tab_stop = false }),
      utils.make_snippet("done", "<<done>>\n\t$0\n<</done>>"),
      utils.make_snippet("goto"),
      utils.make_snippet("repeat", "<<repeat $1>>\n\t$0\n<</repeat>>"),
      utils.make_snippet("stop", nil, { has_tab_stop = false }),
      utils.make_snippet("timed", "<<timed $1>>\n\t$0\n<</timed>>"),
      utils.make_snippet("next"),
      utils.make_snippet("widget", '<<widget "$1">>\n\t$0\n<</widget>>'),
      utils.make_snippet("br", "<br>"),
      utils.make_snippet("span", "<span>$0</span>"),
      utils.make_snippet("div", "<div>\n$0\n</div>"),
    }

    utils.add_symbols_to_completion_table(symbols, "function", items)
    utils.add_symbols_to_completion_table(symbols, "keyword", items)

    completion = {
      isIncomplete = true,
      items = items,
    }
  end

  return callback(nil, completion)
end

---@param params lsp.DefinitionParams
---@param callback function
methods["textDocument/definition"] = function(params, callback)
  local hl_group = utils.get_pos_hl_group(0, nil, nil, { blacklist = { "Comment", "Delimiter", "Operator" } })

  if hl_group == nil then
    return callback(nil, nil)
  end

  local current_word = vim.fn.expand("<cword>")

  ---@type table|nil
  local location = {}

  if vim.list_contains(hl_group, "Conditional") then
    location = utils.find_location(files_content.twee_content, '<<widget "' .. current_word .. '"')
  elseif vim.list_contains(hl_group, "Identifier") then
    location = utils.find_location(files_content.twee_content, "<<set $%f[%a]" .. current_word .. "%f[%A] ")
  elseif vim.list_contains(hl_group, "Function") then
    location = utils.find_location(files_content.js_content, "function %f[%a]" .. current_word .. "%f[%A]%(.*%)")
  end

  return callback(nil, location)
end

---@param params lsp.DocumentHighlightParams
---@param callback function
methods["textDocument/documentHighlight"] = function(params, callback)
  local hl_group = utils.get_pos_hl_group(0, nil, nil, { blacklist = { "Comment", "Delimiter", "Operator" } })

  if hl_group == nil then
    return callback(nil, nil)
  end

  local current_word = vim.fn.expand("<cword>")
  local current_line_content = vim.api.nvim_get_current_line()

  ---@type table|nil
  local document_highlight = {}

  if string.match(current_line_content, "$%f[%a]" .. current_word .. "%f[%A]") then
    document_highlight =
      utils.find_location(files_content, "$%f[%a]" .. current_word .. "%f[%A]", { only_current_buffer = true })
  elseif vim.list_contains(hl_group, "String") then
    local str = utils.get_current_string()

    document_highlight = utils.find_location(files_content.twee_content, str, { only_current_buffer = true })
  else
    document_highlight = utils.find_location(
      files_content.twee_content,
      "%f[%a]" .. current_word .. "%f[%A]",
      { only_current_buffer = true }
    )
  end

  return callback(nil, document_highlight)
end

---@param params lsp.HoverParams
---@param callback function
methods["textDocument/hover"] = function(params, callback)
  local hl_group = utils.get_pos_hl_group(0, nil, nil, { blacklist = { "Comment", "Delimiter", "Operator" } })

  if hl_group == nil then
    return callback(nil, nil)
  end

  local current_word = vim.fn.expand("<cword>")

  ---@type lsp.Hover
  local hover = {
    contents = {
      kind = "plaintext",
      value = current_word,
    },
  }

  if vim.list_contains(hl_group, "Title") then
    hover.contents.value = ("(passage) %s"):format(current_word)
  elseif vim.list_contains(hl_group, "Function") then
    local func = utils.get_symbol(symbols, current_word) or {}
    local func_params = func.parameters and table.concat(func.parameters, ", ") or ""
    local func_docum = func.documentation and "\n---\n" .. func.documentation or ""

    hover.contents.kind = "markdown"
    hover.contents.value = ("```js\n%s(%s)\n```%s"):format(current_word, func_params, func_docum)
  elseif vim.list_contains(hl_group, "Identifier") then
    hover.contents.value = ("(variable) %s"):format(current_word)
  elseif vim.list_contains(hl_group, "Conditional") then
    local widget = utils.get_symbol(symbols, current_word) or {}
    local widget_closed = widget.closed and "<</" .. current_word .. ">>" or ""
    local widget_docum = widget.documentation and "\n---\n" .. widget.documentation or ""

    hover.contents.kind = "markdown"
    hover.contents.value = ("```html\n<<%s>>%s\n```%s"):format(current_word, widget_closed, widget_docum)
  elseif vim.list_contains(hl_group, "String") then
    local str = utils.get_current_string():sub(2, -2)

    hover.contents.value = ("%d bytes"):format(#str)
  end

  return callback(nil, hover)
end

---@param params lsp.ReferenceParams
---@param callback function
methods["textDocument/references"] = function(params, callback)
  local hl_group = utils.get_pos_hl_group(0, nil, nil, { blacklist = { "Comment", "Delimiter", "Operator" } })

  if hl_group == nil then
    return callback(nil, nil)
  end

  local current_word = vim.fn.expand("<cword>")

  ---@type table|nil
  local location = {}

  location = utils.find_location(files_content.twee_content, "%f[%a]" .. current_word .. "%f[%A]")

  return callback(nil, location)
end

local function cmd_fn(dispatchers)
  local closing = false
  local request_id = 0

  local server = {}
  function server.request(method, params, callback)
    local method_impl = methods[method]
    if method_impl ~= nil then
      method_impl(params, callback)
    end

    request_id = request_id + 1
    return true, request_id
  end

  function server.notify(method, params)
    if method == "exit" then
      dispatchers.on_exit(0, 15)
    end
  end

  function server.is_closing()
    return closing
  end

  function server.terminate()
    closing = true
  end

  return server
end

---@param config? vim.lsp.ClientConfig
M.start = function(config)
  local root_dir = vim.fs.root(0, { ".gitignore", "package.json" }) or vim.fn.expand("%:p")
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local namespace = vim.api.nvim_create_namespace("TweeDiagnostics")
  local filetype = { "*.twee", "*.tw" }

  files.load_files(root_dir, files_content, symbols)

  config = config or {}

  config.name = config.name or "tweelsp"
  config.cmd = config.cmd or cmd_fn
  config.root_dir = config.root_dir or root_dir
  config.capabilities = config.capabilities or capabilities

  local client = vim.lsp.start(config)

  ---@diagnostic disable-next-line: param-type-mismatch
  vim.lsp.buf_attach_client(0, client)

  local reload_group = vim.api.nvim_create_augroup("twee-nvim-reload", { clear = true })

  vim.api.nvim_create_autocmd({ "InsertCharPre", "BufWritePost", "InsertLeave", "TextChanged", "BufEnter" }, {
    pattern = filetype,
    group = reload_group,
    callback = function(args)
      local file_buf = vim.uri_to_bufnr(vim.uri_from_fname(args.file))
      if args.buf ~= file_buf then
        return
      end

      files.reload_current_file(files_content, symbols)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost", "User", "TextChanged", "InsertLeave" }, {
    pattern = filetype,
    group = reload_group,
    callback = function(args)
      if args.event == "User" and args.data ~= "twee-nvim-diagnostic-load" then
        return
      end

      utils.get_story_data(files_content.twee_content, symbols)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "VimEnter", "CursorHoldI", "User", "CursorHold" }, {
    pattern = filetype,
    group = vim.api.nvim_create_augroup("twee-nvim-diagnostic", { clear = true }),
    callback = function(args)
      if args.event == "User" and args.data ~= "twee-nvim-diagnostic-load" then
        return
      end

      local diagnostic = {}
      local passage_start_name = vim.g.twee_story_data_start or "Start"
      local buffer = vim.api.nvim_get_current_buf()

      vim.diagnostic.reset(namespace, buffer)

      if utils.get_symbol(symbols, "StoryTitle") == nil then
        vim.list_extend(diagnostic, {
          {
            message = "Passage StoryTitle not found",
            lnum = 0,
            severity = vim.diagnostic.severity.ERROR,
            code = "twee-widget-storytitle-missing",
          },
        })
      end

      if utils.get_symbol(symbols, "StoryData") == nil then
        vim.list_extend(diagnostic, {
          {
            message = "Passage StoryData not found",
            lnum = 0,
            severity = vim.diagnostic.severity.ERROR,
            code = "twee-widget-storydata-missing",
          },
        })
      end

      if utils.get_symbol(symbols, passage_start_name) == nil then
        vim.list_extend(diagnostic, {
          {
            message = "Passage Start not found",
            lnum = 0,
            severity = vim.diagnostic.severity.ERROR,
            code = "twee-widget-start-missing",
          },
        })
      end

      if _G.story_data ~= nil then
        if _G.story_data_invalid_json then
          vim.list_extend(diagnostic, {
            {
              message = "Invalid JSON",
              lnum = _G.story_data_line,
              severity = vim.diagnostic.severity.ERROR,
              code = "twee-json-invalid",
            },
          })

          buffer = vim.uri_to_bufnr(_G.story_data_uri)
        end
      end

      vim.diagnostic.config({ update_in_insert = true, severity_sort = true }, namespace)
      vim.diagnostic.set(namespace, buffer, diagnostic)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = filetype,
    group = vim.api.nvim_create_augroup("twee-nvim-formatting", { clear = true }),
    callback = function()
      if vim.g.twee_formatting == false then
        return
      end

      local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

      local lines_to_remove = {}

      for i, line in ipairs(buf_lines) do
        local next_line = buf_lines[i + 1]

        if line == "" and (next_line == "" or next_line == nil) then
          table.insert(lines_to_remove, i)
        end
      end

      for i = #lines_to_remove, 1, -1 do
        vim.fn.deletebufline(vim.fn.bufname(0), lines_to_remove[i])
      end
    end,
  })
end

return M
