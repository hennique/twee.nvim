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
  local hl_group = utils.get_pos_hl_group()

  if hl_group == "Comment" then
    return callback(nil, nil)
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local line = vim.fn.getline(".")

  local trigger_character = params.context.triggerCharacter

  ---@type lsp.CompletionItem[]
  local completion = {}

  if string.sub(line, math.max(col - 2, 0)) == "<<" or utils.get_pos_hl_group(0, row, col - 1) == "Conditional" then
    utils.add_symbols_to_completion_table(symbols, "widget", completion)
  elseif string.sub(line, math.max(col, 0), col) == "." then
    if utils.get_pos_hl_group(0, row, col - 1) == "Identifier" then
      utils.add_symbols_to_completion_table(symbols, "chain", completion)
    end
  elseif trigger_character == "$" or utils.get_pos_hl_group(0, row, col - 1) == "Identifier" then
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
      {
        label = "StoryTitle",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = ":: StoryTitle\n${0:Sample Text}\n",
        insertText = ":: StoryTitle\n${0:Sample Text}\n\n",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "Start",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = ":: Start\n${0:Sample Text}\n",
        insertText = ":: Start\n${0:Sample Text}\n\n",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "capture",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<capture $1>>\n\t$0\n<</capture>>",
        insertText = "<<capture $1>>\n\t$0\n<</capture>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "set",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<set $0>>",
        insertText = "<<set $0>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "set ... to",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<set $1 to $0>>",
        insertText = "<<set $1 to $0>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "unset",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<unset $0>>",
        textEdit = {
          newText = "<<unset $0>>",
          range = utils.make_textEdit_range("unset"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "run",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<run $0>>",
        textEdit = {
          newText = "<<run $0>>",
          range = utils.make_textEdit_range("run"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "script",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<script ${1|JavaScript,TwineScript|}>>\n\t$0\n<</script>>",
        insertText = "<<script ${1|JavaScript,TwineScript|}>>\n\t$0\n<</script>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "equal",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<= $0>>",
        textEdit = {
          newText = "<<= $0>>",
          range = utils.make_textEdit_range("equal"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "minus",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<- $0>>",
        textEdit = {
          newText = "<<- $0>>",
          range = utils.make_textEdit_range("minus"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "do",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<do>>\n\t$0\n<</do>>",
        insertText = "<<do>>\n\t$0\n<</do>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "include",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<include $0>>",
        textEdit = {
          newText = "<<include $0>>",
          range = utils.make_textEdit_range("include"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "nobr",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<nobr>>\n\t$0\n<</nobr>>",
        insertText = "<<nobr>>\n\t$0\n<</nobr>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "print",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<print $0>>",
        textEdit = {
          newText = "<<print $0>>",
          range = utils.make_textEdit_range("print"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "redo",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<redo $0>>",
        textEdit = {
          newText = "<<redo $0>>",
          range = utils.make_textEdit_range("redo"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "silent",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<silent>>\n\t$0\n<</silent>>",
        insertText = "<<silent>>\n\t$0\n<</silent>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "type",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<type $1>>\n\t$0\n<</type>>",
        insertText = "<<type $1>>\n\t$0\n<</type>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "if",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<if $1>>\n\t$0\n<</if>>",
        insertText = "<<if $1>>\n\t$0\n<</if>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "elseif",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<elseif $0>>",
        insertText = "<<elseif $0>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "else",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<else>>",
        textEdit = {
          newText = "<<else>>",
          range = utils.make_textEdit_range("else"),
        },
      },
      {
        label = "for",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<for $1>>\n\t$0\n<</for>>",
        insertText = "<<for $1>>\n\t$0\n<</for>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "fori",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<for ${1:_i} to 0; ${2:_i} lt ${3:x}; ${4:_i}++>>\n\t$0\n<</for>>",
        insertText = "<<for ${1:_i} to 0; ${2:_i} lt ${3:x}; ${4:_i}++>>\n\t$0\n<</for>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "break",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<break>>",
        textEdit = {
          newText = "<<break>>",
          range = utils.make_textEdit_range("break"),
        },
      },
      {
        label = "continue",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<continue>>",
        textEdit = {
          newText = "<<continue>>",
          range = utils.make_textEdit_range("continue"),
        },
      },
      {
        label = "switch",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<switch ${1:expr}>>\n\t<<case ${2:valueList}>>\n\t\t$3\n\t<<default>>\n\t\t$0\n<</switch>>",
        insertText = "<<switch ${1:expr}>>\n\t<<case ${2:valueList}>>\n\t\t$3\n\t<<default>>\n\t\t$0\n<</switch>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "button",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<button $1>>\n\t$0\n<</button>>",
        insertText = "<<button $1>>\n\t$0\n<</button>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "checkbox",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<checkbox $0>>",
        textEdit = {
          newText = "<<checkbox $0>>",
          range = utils.make_textEdit_range("checkbox"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "cycle",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<cycle $1>>\n\t<<option $2>>\n\t<<option $3>>\n\t$0\n<</cycle>>",
        insertText = "<<cycle $1>>\n\t<<option $2>>\n\t<<option $3>>\n\t$0\n<</cycle>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "link",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<link $1>>\n\t$0\n<</link>>",
        insertText = "<<link $1>>\n\t$0\n<</link>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "linkappend",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<linkappend $1>>\n\t$0\n<</linkappend>>",
        insertText = "<<linkappend $1>>\n\t$0\n<</linkappend>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "linkprepend",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<linkprepend $1>>\n\t$0\n<</linkprepend>>",
        insertText = "<<linkprepend $1>>\n\t$0\n<</linkprepend>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "linkreplace",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<linkreplace $1>>\n\t$0\n<</linkreplace>>",
        insertText = "<<linkreplace $1>>\n\t$0\n<</linkreplace>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "listbox",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<listbox $1>>\n\t<<option $2>>\n\t<<option $3>>\n\t$0\n<</listbox>>",
        insertText = "<<listbox $1>>\n\t<<option $2>>\n\t<<option $3>>\n\t$0\n<</listbox>>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "numberbox",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<numberbox $0>>",
        textEdit = {
          newText = "<<numberbox $0>>",
          range = utils.make_textEdit_range("numberbox"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "radiobutton",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<radiobutton $0>>",
        textEdit = {
          newText = "<<radiobutton $0>>",
          range = utils.make_textEdit_range("radiobutton"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "textarea",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<textarea $0>>",
        textEdit = {
          newText = "<<textarea $0>>",
          range = utils.make_textEdit_range("textarea"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "textbox",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<textbox $0>>",
        textEdit = {
          newText = "<<textbox $0>>",
          range = utils.make_textEdit_range("textbox"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "back",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<back $0>>",
        textEdit = {
          newText = "<<back $0>>",
          range = utils.make_textEdit_range("back"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "return",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = "<<return $0>>",
        textEdit = {
          newText = "<<return $0>>",
          range = utils.make_textEdit_range("return"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "widget",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        detail = '<<widget "$1">>\n\t$0\n<</widget>>',
        insertText = '<<widget "$1">>\n\t$0\n<</widget>>',
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "br",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        textEdit = {
          newText = "<br>",
          range = utils.make_textEdit_range("br"),
        },
      },
      {
        label = "span",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        textEdit = {
          newText = "<span>$0</span>",
          range = utils.make_textEdit_range("span"),
        },
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
      {
        label = "div",
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        insertText = "<div>\n$0\n</div>",
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      },
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

  if hl_group == "Conditional" then
    location = utils.find_location(files_content.twee_content, '<<widget "' .. current_word .. '"')
  elseif hl_group == "Identifier" then
    location = utils.find_location(files_content.twee_content, "<<set $%f[%a]" .. current_word .. "%f[%A] ")
  elseif hl_group == "Function" then
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
  elseif hl_group == "String" then
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

  if hl_group == "Title" then
    hover.contents.value = ("(passage) %s"):format(current_word)
  elseif hl_group == "Identifier" then
    hover.contents.value = ("(variable) %s"):format(current_word)
  elseif hl_group == "Conditional" then
    local widget = utils.get_symbol(symbols, current_word) or {}
    local widget_closed = widget.closed and "<</" .. current_word .. ">>" or ""
    local widget_docum = widget.documentation and "\n---\n" .. widget.documentation or ""

    hover.contents.kind = "markdown"
    hover.contents.value = ("```html\n<<%s>>%s\n```%s"):format(current_word, widget_closed, widget_docum)
  elseif hl_group == "Function" then
    local func = utils.get_symbol(symbols, current_word) or {}
    local func_params = func.parameters and table.concat(func.parameters, ", ") or ""
    local func_docum = func.documentation and "\n---\n" .. func.documentation or ""

    hover.contents.kind = "markdown"
    hover.contents.value = ("```js\n%s(%s)\n```%s"):format(current_word, func_params, func_docum)
  elseif hl_group == "String" then
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
