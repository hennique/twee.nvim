local utils = require("twee.utils")

local M = {}

---@param symbols twee.SymbolsTbl.Symbols
local function add_core_symbols(symbols)
  local sym

  -- ======================================
  -- =============== KEYWORDS ===============
  -- ======================================

  ---@type table<string, twee.Symbol>
  sym = symbols["keyword"]

  sym["to"] = {}
  sym["is"] = {}
  sym["gt"] = {}
  sym["gte"] = {}
  sym["lt"] = {}
  sym["lte"] = {}
  sym["and"] = {}
  sym["or"] = {}
  sym["true"] = {}
  sym["false"] = {}

  -- ======================================
  -- =============== MACROS ===============
  -- ======================================

  ---@type table<string, twee.Symbol>
  sym = symbols["widget"]

  -- Variables macros
  sym["capture"] = {
    closed = true,
    documentation = "Captures story `$variables` and temporary `_variables`, creating localized versions of their values within the macro body.",
  }
  sym["set"] = {
    documentation = "Sets story `$variables` and temporary `_variables` based on the given expression.",
  }
  sym["unset"] = {
    documentation = "Unsets story `$variables`, temporary `_variables`, and properties of objects stored within either.",
  }

  -- Scripting macros
  sym["run"] = {
    documentation = "Functionally identical to `<<set>>`. Intended to be mnemonically better for uses where the expression is arbitrary code, rather than variables to set, i.e., `<<run>>` to run code, `<<set>>` to set variables.",
  }
  sym["script"] = {
    closed = true,
    documentation = "Silently executes its contents as either JavaScript or TwineScript code (default: JavaScript).",
  }

  -- Display macros
  sym["equal"] = {
    documentation = "`<<= expression>>`\n\nOutputs a string representation of the result of the given expression. This macro is an alias for `<<print>>`.",
    insert_text = "<<=>>",
  }
  sym["minus"] = {
    documentation = "`<<- expression>>`\n\nOutputs a string representation of the result of the given expression. This macro is functionally identical to `<<print>>`, save that it also encodes HTML special characters in the output.",
    insert_text = "<<->>",
  }
  sym["do"] = {
    closed = true,
    documentation = "Displays its contents. Listens for `<<redo>>` macro commands upon which it updates its contents.",
  }
  sym["include"] = {
    documentation = "Outputs the contents of the passage with the given name, optionally wrapping it within an HTML element. May be called either with the passage name or with a link markup.",
  }
  sym["nobr"] = {
    closed = true,
    documentation = "Executes its contents and outputs the result, after removing leading/trailing newlines and replacing all remaining sequences of newlines with single spaces.",
  }
  sym["print"] = {
    documentation = "Outputs a string representation of the result of the given expression.",
  }
  sym["redo"] = {
    documentation = "Causes one or more `<<do>>` macros to update their contents.",
  }
  sym["silent"] = {
    closed = true,
    documentation = "Causes any output generated within its body to be discarded, except for errors (which will be displayed). Generally, only really useful for formatting blocks of macros for ease of use/readability, while ensuring that no output is generated, from spacing or whatnot.",
  }
  sym["type"] = {
    closed = true,
    documentation = "Outputs its contents a character, technically, a code point, at a time, mimicking a teletype/typewriter. Can type most content: links, markup, macros, etc.",
  }

  -- Control macros
  sym["if"] = {
    closed = true,
    documentation = "Executes its contents if the given conditional expression evaluates to true. If the condition evaluates to false and an `<<elseif>>` or `<<else>>` exists, then other contents can be executed.",
  }
  sym["elseif"] = {}
  sym["else"] = {}
  sym["for"] = {
    closed = true,
    documentation = "Repeatedly executes its contents.",
  }
  sym["break"] = {
    documentation = "Used within `<<for>>` macros. Terminates the execution of the current `<<for>>`.",
  }
  sym["continue"] = {
    documentation = "Used within `<<for>>` macros. Terminates the execution of the current iteration of the current `<<for>>` and begins execution of the next iteration.",
  }
  sym["switch"] = {
    closed = true,
    documentation = "Evaluates the given expression and compares it to the value(s) within its `<<case>>` children. The value(s) within each case are compared to the result of the expression given to the parent `<<switch>>`. Upon a successful match, the matching case will have its contents executed. If no cases match and an optional `<<default>>` case exists, which must be the final case, then its contents will be executed. At most one case will execute.",
  }
  sym["case"] = {
    documentation = "`<<case valueList>>`\n\n- valueList: A space separated list of values to compare against the result of the switch expression.",
  }
  sym["default"] = {
    documentation = "The default case executed if none of the cases match",
  }

  -- Interactive macros
  sym["button"] = {
    closed = true,
    documentation = "Creates a button that silently executes its contents when clicked, optionally forwarding the player to another passage. May be called with either the link text and passage name as separate arguments, a link markup, or an image markup.",
  }
  sym["checkbox"] = {
    documentation = "Creates a checkbox, used to modify the value of the variable with the given name.",
  }
  sym["cycle"] = {
    closed = true,
    documentation = "Creates a cycling link, used to modify the value of the variable with the given name. The cycling options are populated via `<<option>>` and/or `<<optionsfrom>>`.",
  }
  sym["link"] = {
    closed = true,
    documentation = "Creates a link that silently executes its contents when clicked, optionally forwarding the player to another passage. May be called with either the link text and passage name as separate arguments, a link markup, or an image markup.",
  }
  sym["linkappend"] = {
    closed = true,
    documentation = "Creates a single-use link that deactivates itself and appends its contents to its link text when clicked. Essentially, a combination of `<<link>>` and `<<append>>`.",
  }
  sym["linkprepend"] = {
    closed = true,
    documentation = "Creates a single-use link that deactivates itself and prepends its contents to its link text when clicked. Essentially, a combination of `<<link>>` and `<<prepend>>`.",
  }
  sym["linkreplace"] = {
    closed = true,
    documentation = "Creates a single-use link that deactivates itself and replaces its link text with its contents when clicked. Essentially, a combination of `<<link>>` and `<<replace>>`.",
  }
  sym["listbox"] = {
    closed = true,
    documentation = "Creates a listbox, used to modify the value of the variable with the given name. The list options are populated via `<<option>>` and/or `<<optionsfrom>>`.",
  }
  sym["numberbox"] = {
    documentation = "Creates a number input box, used to modify the value of the variable with the given name, optionally forwarding the player to another passage.",
  }
  sym["radiobutton"] = {
    documentation = "Creates a radio button, used to modify the value of the variable with the given name. Multiple `<<radiobutton>>` macros may be set up to modify the same variable, which makes them part of a radio button group.",
  }
  sym["textarea"] = {
    documentation = "Creates a multiline text input block, used to modify the value of the variable with the given name.",
  }
  sym["textbox"] = {
    documentation = "Creates a text input box, used to modify the value of the variable with the given name, optionally forwarding the player to another passage.",
  }

  -- Links macros
  sym["back"] = {
    documentation = "Creates a link that undoes past moments within the story history. May be called with, optional, the link text and passage name as separate arguments, a link markup, or an image markup.",
  }
  sym["return"] = {
    documentation = "Creates a link that navigates forward to a previously visited passage. May be called with, optional, the link text and passage name as separate arguments, a link markup, or an image markup.",
  }

  -- DOM macros
  sym["addclass"] = {
    documentation = "Adds classes to the selected element(s).",
  }
  sym["append"] = {
    closed = true,
    documentation = "Executes its contents and appends the output to the contents of the selected element(s).",
  }
  sym["copy"] = {
    documentation = "Outputs a copy of the contents of the selected element(s).",
  }
  sym["prepend"] = {
    closed = true,
    documentation = "Executes its contents and prepends the output to the contents of the selected element(s).",
  }
  sym["remove"] = {
    documentation = "Removes the selected element(s).",
  }
  sym["removeclass"] = {
    documentation = "Removes classes from the selected element(s).",
  }
  sym["replace"] = {
    closed = true,
    documentation = "Executes its contents and replaces the contents of the selected element(s) with the output.",
  }
  sym["toggleclass"] = {
    documentation = "Toggles classes on the selected element(s), i.e., adding them if they don't exist, removing them if they do.",
  }

  -- Audio macros
  sym["audio"] = {
    documentation = "Controls the playback of audio tracks, which must be set up via `<<cacheaudio>>`.",
  }
  sym["cacheaudio"] = {
    documentation = "Caches an audio track for use by the other audio macros.",
  }
  sym["createaudiogroup"] = {
    closed = true,
    documentation = "Collects tracks, which must be set up via `<<cacheaudio>>`, into a group via its `<<track>>` children. Groups are useful for applying actions to multiple tracks simultaneously and/or excluding the included tracks from a larger set when applying actions.",
  }
  sym["createplaylist"] = {
    closed = true,
    documentation = "Collects tracks, which must be set up via `<<cacheaudio>>`, into a playlist via its `<<track>>` children.",
  }
  sym["track"] = {}
  sym["masteraudio"] = {
    documentation = "Controls the master audio settings.",
  }
  sym["playlist"] = {
    documentation = "Controls the playback of the playlist, which must be set up via `<<createplaylist>>`.",
  }
  sym["removeaudiogroup"] = {
    documentation = "Removes the audio group with the given ID.",
  }
  sym["removeplaylist"] = {
    documentation = "Removes the playlist with the given ID.",
  }
  sym["waitforaudio"] = {
    documentation = "Displays the loading screen until all currently registered audio has either loaded to a playable state or aborted loading due to errors. Requires tracks to be set up via `<<cacheaudio>>`.",
  }

  -- Miscellaneous macros
  sym["done"] = {
    closed = true,
    documentation = "Silently executes its contents when the incoming passage is done rendering and has been added to the page. Generally, only really useful for running code that needs to manipulate elements from the incoming passage, since you must wait until they've been added to the page.",
  }
  sym["goto"] = {
    documentation = "Immediately forwards the player to the passage with the given name. May be called either with the passage name or with a link markup.\n\nIn most cases, you will not need to use `<<goto>>` as there are often better and easier ways to forward the player. For example, a common use of `<<link>>` is to perform various actions before forwarding the player to another passage. In that case, unless you need to dynamically determine the destination passage within the `<<link>>` body, `<<goto>>` is unnecessary as `<<link>>` already includes the ability to forward the player. ",
  }
  sym["repeat"] = {
    closed = true,
    documentation = "Repeatedly executes its contents after the given delay, inserting any output into the passage in its place. May be terminated by a `<<stop>>` macro.",
  }
  sym["stop"] = {
    documentation = "Used within `<<repeat>>` macros. Terminates the execution of the current `<<repeat>>`.",
  }
  sym["timed"] = {
    closed = true,
    documentation = table.concat({
      "```",
      "<<timed delay [transition|t8n]>> ..",
      "\t[<<next [delay]>> ..]",
      "<</timed>>",
      "```",
      "",
      "Executes its contents after the given delay, inserting any output into the passage in its place. Additional timed executions may be chained via `<<next>>`.",
      "",
      "Arguments:",
      "- `<<timed>>`",
      "\t- `delay`: The amount of time to delay, as a valid CSS time value, e.g., `5s` and `500ms`. The minimum delay is `40ms`.",
      "\t- `transition`: (optional) Keyword, used to signify that a CSS transition should be applied to the incoming insertions.",
      "\t- `t8n`: (optional) Keyword, alias for `transition`.",
      "",
      "- `<<next>>`",
      "\t- `delay`: (optional) The amount of time to delay, as a valid CSS time value, e.g., `5s` and `500ms`. The minimum delay is `40ms`. If omitted, the last delay specified, from a `<<next>>` or the parent `<<timed>>`, will be used.",
    }, "\n"),
  }
  sym["widget"] = {
    closed = true,
    documentation = "Creates a new widget macro (henceforth, widget) with the given name. Widgets allow you to create macros by using the standard macros and markup that you use normally within your story. All widgets may access arguments passed to them via the `_args` special variable. Block widgets may access the contents they enclose via the `_contents` special variable.",
  }

  -- =========================================
  -- =============== FUNCTIONS ===============
  -- =========================================

  ---@type table<string, twee.Symbol>
  sym = symbols["function"]

  sym["clone"] = {
    documentation = "Returns a deep copy of the given value.\n\n- `original`: (`any`) The value to clone.",
    parameters = { "original" },
  }
  sym["either"] = {
    documentation = "Returns a random value from its given arguments.\n\n- `list`: (`any`) The list of values to operate on. May be any combination of singular values, actual arrays, or array-like objects. All values will be concatenated into a single list for selection. NOTE: Does not flatten nested arrays, if this is required, the `<Array>.flat()` method may be used to flatten the nested arrays prior to passing them to `either()`.",
    parameters = { "list..." },
  }
  sym["forget"] = {
    documentation = "Removes the specified key, and its associated value, from the story metadata store.\n\n- `key`: (`string`) The key to remove.",
    parameters = { "key" },
  }
  sym["hasVisited"] = {
    documentation = "Returns whether the passage with the given name occurred within the story history. If multiple passage names are given, returns the logical-AND aggregate of the set, i.e., `true` if all were found, `false` if any were not found.\n\n- `passages`: (`string`|`Array<string>`) The name(s) of the passage(s) to search for. May be a list or an array of passages.",
    parameters = { "passages..." },
  }
  sym["lastVisited"] = {
    documentation = "Returns the number of turns that have passed since the last instance of the passage with the given name occurred within the story history or `-1` if it does not exist. If multiple passage names are given, returns the lowest count (which can be `-1`).\n\n- `passages`: (`string`|`Array<string>`) The name(s) of the passage(s) to search for. May be a list or an array of passages.",
    parameters = { "passages..." },
  }
  sym["importScripts"] = {
    documentation = "Load and integrate external JavaScript scripts.\n\n- `urls`: (`string`|`object`|`Array<string | object`) The URLs of the external scripts to import. Loose URLs are imported concurrently, arrays of URLs are imported sequentially. URLs may also be specified as objects with a `type` and a `src` property.",
    parameters = { "urls..." },
  }
  sym["importStyles"] = {
    documentation = "Load and integrate external CSS stylesheets.\n\n- `urls`: (`string` | `Array<string>`) The URLs of the external stylesheets to import. Loose URLs are imported concurrently, arrays of URLs are imported sequentially.",
    parameters = { "urls..." },
  }
  sym["memorize"] = {
    documentation = "Sets the specified key and value within the story metadata store, which causes them to persist over story and browser restarts. To update the value associated with a key, simply set it again.\n\n- `key`: (`string`) The key that should be set.\n- `value`: (`any`) The value to set.",
    parameters = { "key", "value" },
  }
  sym["passage"] = {
    documentation = "Returns the name of the active (present) passage.",
  }
  sym["previous"] = {
    documentation = "Returns the name of the most recent previous passage whose name does not match that of the active passage or an empty string, if there is no such passage.",
  }
  sym["random"] = {
    documentation = "Returns a pseudo-random whole number (integer) within the range of the given bounds (inclusive), i.e., [min, max].\n\n- `min`: (optional, `integer`) The lower bound of the random number (inclusive). If omitted, will default to `0`.\n- `max`: (`integer`) The upper bound of the random number (inclusive).",
    parameters = { "[min, ] max" },
  }
  sym["randomFloat"] = {
    documentation = "Returns a pseudo-random decimal number (floating-point) within the range of the given bounds (inclusive for the minimum, exclusive for the maximum), i.e., [min, max).\n\n- `min`: (optional, `decimal`) The lower bound of the random number (inclusive). If omitted, will default to `0.0`.\n- `max`: (`decimal`) The upper bound of the random number (inclusive).",
    parameters = { "[min, ] max" },
  }
  sym["recall"] = {
    documentation = "Returns the value associated with the specified key from the story metadata store or, if no such key exists, the specified default value, if any.\n\n- `key`: (`string`) The key whose value should be returned.\n`defaultValue`: (optional, `any`) The value to return if the key doesn't exist.",
    parameters = { "key [, defaultValue]" },
  }
  sym["setPageElement"] = {
    documentation = "Renders the selected passage into the target element, replacing any existing content, and returns the element. If no passages are found and default text is specified, it will be used instead.\n\n- `idOrElement`: (`string` | `HTMLElement`) The ID of the element or the element itself.\n- `passages`: (`string` | `Array<string>`) The name(s) of the passage(s) to search for. May be a single passage or an array of passages. If an array of passage names is specified, the first passage to be found is used.\n- `defaultText`: (optional, `string`) The default text to use if no passages are found.",
    parameters = { "idOrElement", "passages [, defaultText]" },
  }
  sym["tags"] = {
    documentation = "Returns a new array consisting of all of the tags of the given passages.\n\n- `passages`: (optional, `string` | `Array<string>`) The passages from which to collect tags. May be a list or an array of passages. If omitted, will default to the active (present) passage, included passages do not count for this purpose; e.g., passages pulled in via `<<include>>`, `PassageHeader`, etc.",
    parameters = { "[passages...]" },
  }
  sym["temporary"] = {
    documentation = "Returns a reference to the current temporary variables store (equivalent to: `State.temporary`). This is only really useful within pure JavaScript code, as within TwineScript you may simply access temporary variables natively.",
  }
  sym["time"] = {
    documentation = "Returns the number of milliseconds that have passed since the current passage was rendered to the page.",
  }
  sym["triggerEvent"] = {
    documentation = "Dispatches a synthetic event with the given name, optionally on the given targets and with the given options.\n\n- `name`: (`string`) The name of the event to trigger. Both native and custom events are supported.\n- `targets`: (optional, `Document` | `HTMLElement` | `jQuery` | `NodeList` | `Array<HTMLElement>`) The target(s) to trigger the event on. If omitted, will default to `document`.\n- `options`: (optional, `object`) The options to be used when dispatching the event. See below for details.\n\nAn event options object should have some of the following properties:\n- `bubbles`: (optional, `boolean`) Whether the event bubbles (default: `true`).\n- `cancelable`: (optional, `boolean`) Whether the event is cancelable (default: `true`).\n- `composed`: (optional, `boolean`) Whether the event triggers listeners outside of a shadow root (default: `false`).\n- `detail`: (optional, `any`) Custom data sent with the event (default: `undefined`). Although any type is allowable, an object is often the most practical.",
    parameters = { "name [, targets [, options]]" },
  }
  sym["turns"] = {
    documentation = "Returns the total number (count) of played turns currently in effect, i.e., the number of played moments up to the present moment; future (rewound/undone) moments are not included within the total.",
  }
  sym["variables"] = {
    documentation = "Returns a reference to the active (present) story variables store (equivalent to: `State.variables`). This is only really useful within pure JavaScript code, as within TwineScript you may simply access story variables natively.",
  }
  sym["visited"] = {
    documentation = "Returns the number of times that the passage with the given title occurred within the story history. If multiple passage titles are given, returns the lowest count.\n\n- `passages`: (optional, `string` | `Array<string>`) The title(s) of the passage(s) to search for. May be a list or an array of passages. If omitted, will default to the current passage.",
    parameters = { "[passages…]" },
  }
  sym["visitedTags"] = {
    documentation = "Returns the number of passages within the story history that are tagged with all of the given tags.\n\n- `tags`: (`string` | `Array<string>`) The tags to search for. May be a list or an array of tags.",
    parameters = { "tags..." },
  }
end

--- Loads contents of twee and javascript files, and symbols of twee files.
---@param path string Path to begin searching from
---@param content twee.ContentTbl Table to save contents of files
---@param symbols twee.SymbolsTbl Table to save all symbols found
---@param callback? function Callback function to call after files loaded
function M.load_files(path, content, symbols, callback)
  vim.schedule(function()
    vim.notify("Loading workspace")

    local buf_name = vim.api.nvim_buf_get_name(0)

    if path == buf_name then
      local file_uri = vim.uri_from_bufnr(0)
      local file_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

      content.twee_content[file_uri] = file_lines

      vim.notify("Workspace loaded")

      vim.api.nvim_exec_autocmds("User", {
        data = "twee-nvim-diagnostic-load",
      })

      if callback == nil then
        return
      end

      callback()
      return
    end

    local files = vim.fs.find(function(name)
      return vim.list_contains({ "twee", "tw", "js" }, vim.fs.ext(name))
    end, { limit = math.huge, type = "file", path = path })

    local yml_files = vim.fs.find(function(name)
      return string.match(name, ".*twee%-config%.yml$")
    end, { limit = math.huge, type = "file", path = path })

    symbols["global_symbols"] = {
      widget = {},
      ["function"] = {},
      passage = {},
      variable = {},
      keyword = {},
    }

    local global_symbol = symbols["global_symbols"]

    add_core_symbols(global_symbol)

    local file_type = {
      js = "js_content",
      twee = "twee_content",
      tw = "twee_content",
    }

    local yml = {}
    debug.setmetatable(nil, { __index = {} })

    vim.uv.fs_opendir(path, function(_, dir)
      for _, filename in ipairs(yml_files) do
        vim.uv.fs_open(filename, "r", tonumber("444", 8), function(_, fd)
          local stat = vim.uv.fs_fstat(fd) ---@cast stat uv.fs_stat.result
          local file_content = vim.uv.fs_read(fd, stat.size) ---@cast file_content string
          yml = vim.tbl_deep_extend("force", yml, utils.parse_yml(file_content))

          vim.uv.fs_close(fd)
        end)
      end

      for _, filename in ipairs(files) do
        vim.uv.fs_open(filename, "r", tonumber("444", 8), function(_, fd)
          local stat = vim.uv.fs_fstat(fd) ---@cast stat uv.fs_stat.result
          local file_content = vim.uv.fs_read(fd, stat.size) ---@cast file_content string

          local file_lines = vim.split(file_content, "\n")
          local file_uri = vim.uri_from_fname(filename)
          local file_ext = file_type[vim.fs.ext(filename)]

          content[file_ext][file_uri] = file_lines

          for symbol, value in string.gmatch(file_content, "<<set $([a-zA-Z_.]+) %S+ (.-)>>") do
            local variable_tbl = vim.split(symbol, "%.") or { symbol, nil }

            local item = global_symbol["variable"][variable_tbl[1]] or {}
            local next_var = item.next or {}
            global_symbol["variable"][variable_tbl[1]] =
              { uri = file_uri, line = 1, ["next"] = next_var, value = value }

            for j = 2, #variable_tbl do
              next_var[variable_tbl[j]] = next_var[variable_tbl[j]] or {}
              next_var = next_var[variable_tbl[j]]
            end
          end
          for symbol in string.gmatch(file_content, '<<widget "([a-zA-Z_]+)">>') do
            local documentation = yml["sugarcube-2"]["macros"][symbol]["description"] or nil
            local deprecated = yml["sugarcube-2"]["macros"][symbol]["deprecated"] or false
            local deprecated_suggestions = yml["sugarcube-2"]["macros"][symbol]["deprecatedSuggestions"] or nil

            global_symbol["widget"][symbol] = {
              uri = file_uri,
              line = 1,
              documentation = documentation,
              deprecated = deprecated,
              deprecated_suggestions = deprecated_suggestions,
            }
          end
          for symbol in string.gmatch(file_content, ":: (%w+)") do
            global_symbol["passage"][symbol] = { uri = file_uri, line = 1 }
          end

          vim.uv.fs_close(fd)
        end)
      end

      print("Workspace loaded")

      if callback == nil then
        return
      end

      callback()

      vim.uv.fs_closedir(dir)
    end)

    vim.api.nvim_exec_autocmds("User", {
      data = "twee-nvim-diagnostic-load",
    })
  end)
end

--- Reloads contents and symbols of the current file
---@param content twee.ContentTbl
---@param symbols twee.SymbolsTbl
function M.reload_current_file(content, symbols)
  local uri = vim.uri_from_bufnr(0)
  local file_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  content.twee_content[uri] = file_content
  symbols["buf_symbols"] = {
    variable = {},
    ["function"] = {},
    passage = {},
    widget = {},
    keyword = {},
  }

  local buf_symbol = symbols["buf_symbols"]

  add_core_symbols(buf_symbol)

  for i, line in ipairs(file_content) do
    for symbol, value in string.gmatch(line, "<<set $([a-zA-Z_.]+) %S+ (.-)>>") do
      local variable_tbl = vim.split(symbol, "%.") or { symbol, nil }

      local item = buf_symbol["variable"][variable_tbl[1]] or {}
      local next_var = item.next or {}
      buf_symbol["variable"][variable_tbl[1]] = { uri = uri, line = i, ["next"] = next_var, value = value }

      for j = 2, #variable_tbl do
        next_var[variable_tbl[j]] = next_var[variable_tbl[j]] or {}
        next_var = next_var[variable_tbl[j]]
      end
    end
    for symbol in string.gmatch(line, '<<widget "([a-zA-Z_]+)">>') do
      buf_symbol["widget"][symbol] = { uri = uri, line = i }
    end
    for symbol in string.gmatch(line, ":: (%w+)") do
      buf_symbol["passage"][symbol] = { uri = uri, line = i }
    end
  end
end

return M
