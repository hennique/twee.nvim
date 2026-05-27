vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("twee-nvim", { clear = true }),
  pattern = { "*.twee", "*.tw" },
  callback = function()
    require("twee.filetype").set()
  end,
})
