local M = {}

M.set = function()
  vim.cmd.setfiletype("twee")
  vim.cmd.syntax([[keyword Keyword lt lte gt gte eq not and or is to]])
  vim.cmd.syntax([[keyword Boolean true false]])
  vim.cmd.syntax([[keyword ToDo TODO XXX FIXME]])
  vim.cmd.syntax([=[match Underlined "\[\[\_.\{-}\]\]"]=])
  vim.cmd.syntax([[match Function "\w\+\((.*)\)\@="]])
  vim.cmd.syntax([[match Conditional "\(<<\/\=\)\@<=\w\+"]]) -- Macros
  vim.cmd.syntax([[match Constant "<\/\=[A-Za-z0-9]\+.\{-}>"]]) -- HTML tags
  vim.cmd.syntax([[match Identifier /\$[A-Za-z0-9_.?]*/ contains=Ignore,Delimiter]])
  vim.cmd.syntax([[match Title /^[*#]/]])
  vim.cmd.syntax([[match Type /\[.*\]/]])
  vim.cmd.syntax([[match Number /[0-9]/]])
  vim.cmd.syntax([[match Operator "[-+=/*]\|=>"]])
  vim.cmd.syntax([[match Ignore /[!]/]])
  vim.cmd.syntax([=[match Delimiter "[:.,(){}\[\]]\|<<\|>>" contains=Underlined]=])
  vim.cmd.syntax([[match Title /^::.*$/ contains=Type]])
  vim.cmd.syntax([[region String start=+"+ end=+"+]])
  vim.cmd.syntax([[region Comment start="[/][*]" end="[*][/]"]])
  vim.cmd.syntax([[region Comment start="<!--" end="-->"]])
end

return M
