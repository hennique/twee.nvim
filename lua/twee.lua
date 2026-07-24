local M = {}

---@param config? table
function M.setup(config)
  config = config or {}
  config.formatting = config.formatting or true

  vim.g.twee_story_data_start = "Start"
  vim.g.twee_formatting = config.formatting
end

return M
