vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("twee-nvim-init", { clear = true }),
  pattern = { "*.twee", "*.tw" },
  callback = function()
    require("twee").setup()
    require("twee.filetype").set()
    require("twee.lsp").start()
  end,
})

vim.api.nvim_create_user_command("TweeCompile", function()
  if not vim.list_contains({ "twee", "tw" }, vim.bo.filetype) then
    vim.notify("You must be in a twee file.")
    return
  end

  local ok = pcall(vim.system, { "tweego" })
  if not ok then
    vim.notify("You must have Tweego installed.")
    return
  end

  vim.system({ "tweego", "-o", vim.fn.expand("%:p:r") .. ".html", vim.fn.expand("%:p") }, function(obj)
    if obj.code == 1 then
      print(obj.stderr)
    end
  end)
end, { desc = "Compiles the current file into a html using Tweego" })
