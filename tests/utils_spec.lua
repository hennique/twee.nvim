local utils = require("twee.utils")
local find_location = utils.find_location
local get_symbol = utils.get_symbol
local make_range = utils.make_range

describe("twee.utils.find_location", function()
  local content = {
    twee_content = {
      ["file:///home/user/Documents/Development/start.twee"] = {
        ":: StoryTitle",
        "A Title",
        "",
        ":: StoryData",
        "{",
        ' "ifid": "XXXXXXXXXXX-XXXXX-XXXXXXX"',
        "}",
        "",
        ":: Start",
        "A really cool start",
      },
    },
    js_content = {},
  }

  it("should return location of all passages", function()
    local expected = {
      {
        uri = "file:///home/user/Documents/Development/start.twee",
        range = {
          start = {
            line = 0,
            character = 0,
          },
          ["end"] = {
            line = 0,
            character = 13,
          },
        },
      },
      {
        uri = "file:///home/user/Documents/Development/start.twee",
        range = {
          start = {
            line = 3,
            character = 0,
          },
          ["end"] = {
            line = 3,
            character = 12,
          },
        },
      },
      {
        uri = "file:///home/user/Documents/Development/start.twee",
        range = {
          start = {
            line = 8,
            character = 0,
          },
          ["end"] = {
            line = 8,
            character = 8,
          },
        },
      },
    }
    local actual = find_location(content.twee_content, ":: %a+")

    assert.equals(vim.json.encode(expected), vim.json.encode(actual))
  end)

  it("should return nil", function()
    local expected = nil
    local actual = find_location(content, "Return of the king")

    assert.equals(expected, actual)
  end)
end)

describe("twee.utils.get_symbol", function()
  local symbol = {
    global_symbols = {
      variable = {
        ["example1"] = { uri = "file:///home/user/Development/file1.twee", line = 5 },
        ["example2"] = { uri = "file:///home/user/Development/file1.twee", line = 6 },
      },
      passage = {
        ["example3"] = { uri = "file:///home/user/Development/file2.twee", line = 23 },
      },
      widget = {
        ["example4"] = { uri = "file:///home/user/Development/file3.twee", line = 14 },
      },
    },
    buf_symbols = {
      variable = {
        ["buf_example1"] = { uri = "file:///home/user/Development/buf_file.twee", line = 20 },
        ["buf_example2"] = { uri = "file:///home/user/Development/buf_file.twee", line = 45 },
      },
    },
  }

  it("should return a table containing uri and line", function()
    local expected = {
      uri = "file:///home/user/Development/file1.twee",
      line = 5,
    }
    local actual = get_symbol(symbol, "example1")

    assert.equals(vim.json.encode(expected), vim.json.encode(actual))
  end)

  it("should return nil", function()
    local expected = nil
    local actual = get_symbol(symbol, "nil_example")

    assert.equals(expected, actual)
  end)
end)

describe("twee.utils.make_range", function()
  it("should return a range", function()
    local expected = {
      start = {
        line = 16,
        character = 3,
      },
      ["end"] = {
        line = 45,
        character = 23,
      },
    }
    local actual = make_range(16, 3, 45, 23)

    assert.equals(vim.json.encode(expected), vim.json.encode(actual))
  end)
end)
