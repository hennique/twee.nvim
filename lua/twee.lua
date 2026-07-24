local M = {}

M.did_setup = false

---@param config? table
function M.setup(config)
  config = config or {}

  if config.formatting == nil then
    config.formatting = true
  end

  vim.g.twee_story_data_start = "Start"
  vim.g.twee_formatting = config.formatting

  M.did_setup = true
end

return M
