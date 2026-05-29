local M = {}

---@param config? table
M.setup = function(config)
  config = config or {}

  vim.g.twee_story_data_start = "Start"
end

return M
