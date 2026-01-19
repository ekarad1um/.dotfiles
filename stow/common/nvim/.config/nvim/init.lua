-- Load vimrc file for compatibility with vim plugins
vim.cmd([[
  set runtimepath^=~/.vim runtimepath+=~/.vim/after
  let &packpath = &runtimepath
  source ~/.vimrc
]])

-- Make background transparent
local transparent_highlights = { 'Normal', 'NormalFloat', 'FloatBorder', 'Pmenu' }
for _, group in ipairs(transparent_highlights) do
  vim.api.nvim_set_hl(0, group, { bg = 'none' })
end

-- Set status line colors
vim.api.nvim_set_hl(0, 'StatusLine', { fg = '#eeeeee', bg = 'none' })
vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = '#888888', bg = 'none' })

-- Set tab line colors
vim.api.nvim_set_hl(0, 'TabLineSel', { fg = 'black', bg = 'none', bold = true })
vim.api.nvim_set_hl(0, 'TabLine', { fg = 'black', bg = 'none' })
vim.api.nvim_set_hl(0, 'TabLineFill', { fg = 'none', bg = '#eeeeee' })

-- Hide command line unless needed
vim.opt.cmdheight = 0
vim.opt.showcmd = true

-- Set netrw lexplore keymap
vim.keymap.set('n', '<M-e>', vim.cmd.Lexplore)

-- Tab management keymaps
vim.keymap.set('n', '<M-Tab>', ':tabs<CR>')
vim.keymap.set('n', '<M-n>', ':tabnew<CR>')
vim.keymap.set('n', '<M-w>', function()
  if #vim.api.nvim_list_tabpages() == 1 then
    vim.cmd('quit')
  else
    vim.cmd('tabclose')
  end
end)

-- Keymaps to switch to specific tabs
for i = 1, 9 do
  vim.keymap.set('n', '<M-' .. i .. '>', i .. 'gt')
end
vim.keymap.set('n', '<M-0>', ':tablast<CR>')

-- Remap Emacs-style keybindings command modes
-- Navigation
vim.keymap.set('c', '<C-a>', '<Home>')
vim.keymap.set('c', '<C-e>', '<End>')
vim.keymap.set('c', '<C-b>', '<Left>')
vim.keymap.set('c', '<C-f>', '<Right>')
vim.keymap.set('c', '<C-p>', '<Up>')
vim.keymap.set('c', '<C-n>', '<Down>')
-- Word-wise navigation
vim.keymap.set('c', '<M-b>', '<C-Left>')
vim.keymap.set('c', '<M-f>', '<C-Right>')
-- Killing and deleting
vim.keymap.set('c', '<C-k>', '<C-u>')
-- Word-wise deleting
vim.keymap.set('c', '<M-BS>', '<C-w>')
vim.keymap.set('c', '<M-d>', '<C-w>')

-- Auto close lsp document symbol window after jump
local symbol_group = vim.api.nvim_create_augroup("LspSymbolWindow", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = symbol_group,
  pattern = "qf",
  callback = function(event)
    local win_info = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
    if not win_info then return end
    local close_cmd = win_info.loclist == 1 and ":lclose<CR>" or ":cclose<CR>"
    vim.keymap.set("n", "<CR>", "<CR>" .. close_cmd, { buffer = event.buf, remap = true, silent = true })
  end,
})

-- Terminal mode keymaps
vim.keymap.set('n', '<M-t>', ':vsp|term<CR>')
vim.keymap.set('t', '<M-w>', [[<C-\><C-n>:q!<CR>]], { noremap = true })
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { noremap = true })
vim.keymap.set('t', '<C-h>', [[<C-\><C-n><C-w>h]], { noremap = true })
vim.keymap.set('t', '<C-j>', [[<C-\><C-n><C-w>j]], { noremap = true })
vim.keymap.set('t', '<C-k>', [[<C-\><C-n><C-w>k]], { noremap = true })
vim.keymap.set('t', '<C-l>', [[<C-\><C-n><C-w>l]], { noremap = true })

-- Auto enter insert mode when opening or switching to a terminal buffer
local term_group = vim.api.nvim_create_augroup("NeovimTerminal", { clear = true })
vim.api.nvim_create_autocmd("TermOpen", {
  group = term_group,
  pattern = "*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd("startinsert")
  end,
})
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = term_group,
  pattern = "term://*",
  command = "startinsert",
})

-- Enable LSP servers (https://github.com/neovim/nvim-lspconfig)
vim.lsp.enable({
  'clangd',
  'ruff', 'rust_analyzer',
  'svelte', 'tsgo'
})

-- Enable native autocompletion
local completion_group = vim.api.nvim_create_augroup("LspCompletion", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
  group = completion_group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, {
        autotrigger = true,
      })
    end
  end,
})
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.shortmess:append("c")
vim.opt.completeopt:append("fuzzy")

-- Toggle inlay hints
vim.keymap.set('n', '<Leader>ih', function()
  local is_enabled = vim.lsp.inlay_hint.is_enabled()
  vim.lsp.inlay_hint.enable(not is_enabled)
end)

-- Rename symbol keymap
vim.keymap.set('n', '<Leader>rn', vim.lsp.buf.rename)

-- Format document keymap
vim.keymap.set('n', '<Leader>f', function()
  vim.lsp.buf.format({ async = true })
end)

-- Configure nvim treesitter to install parsers (https://github.com/nvim-treesitter/nvim-treesitter)
require('nvim-treesitter').install({
  'asm',
  'c', 'cmake', 'cpp', 'css', 'csv',
  'diff',
  'glsl',
  'html',
  'javascript', 'json',
  'latex', 'llvm', 'lua',
  'make', 'mlir',
  'rust',
  'ssh_config', 'strace', 'svelte', 'swift',
  'tmux', 'toml', 'tsx', 'typescript',
  'vim',
  'xml',
  'yaml',
  'zsh'
})
