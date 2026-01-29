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

-- Open new splits to the right and below
vim.opt.splitright = true

-- Keymaps to switch to specific tabs
for i = 1, 9 do
    vim.keymap.set('n', '<M-' .. i .. '>', i .. 'gt', { noremap = true })
end
vim.keymap.set('n', '<M-0>', ':tablast<CR>', { noremap = true })

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

-- Hex mode toggle keymap
vim.keymap.set("n", "<leader>h", function()
    if vim.b.is_hex then
        vim.cmd("%!xxd -r")
        vim.b.is_hex = false
        vim.opt_local.binary = false
    else
        vim.opt_local.binary = true
        vim.cmd("%!xxd")
        vim.b.is_hex = true
    end
end, { noremap = true })

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

-- Setup mini.icons
require('mini.icons').setup({
    style = 'ascii',
})
-- Setup mini.pick
require("mini.pick").setup({
    options = {
        content_from_bottom = false,
        use_cache = true,
    }
})
vim.keymap.set('n', '<M-p>', function() MiniPick.builtin.files({ tool = 'git' }) end, { noremap = true })

-- LSP servers (https://github.com/neovim/nvim-lspconfig)
vim.lsp.enable({
    'clangd',
    'lua_ls',
    'ruff', 'rust_analyzer',
    'svelte', 'tsgo'
})

-- LSP native autocompletion
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

-- LSP symbol navigation keymaps
vim.keymap.set('n', '<leader>ds', function()
    vim.lsp.buf.document_symbol({
        on_list = function(options)
            local items = {}
            for _, item in ipairs(options.items) do
                local kind = item.kind
                if kind == 'Function' or kind == 'Method' or kind == 'Class' or kind == 'Struct' then
                    table.insert(items, item)
                end
            end
            if #items == 0 then items = options.items end
            vim.fn.setloclist(0, items, 'r')
            vim.cmd("lopen")
        end
    })
end, { noremap = true })
vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol, { noremap = true })

-- LSP inlay hints toggle keymap
vim.keymap.set('n', '<leader>ih', function()
    local is_enabled = vim.lsp.inlay_hint.is_enabled()
    vim.lsp.inlay_hint.enable(not is_enabled)
end)

-- LSP rename symbol keymap
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { noremap = true })

-- LSP format document keymap
vim.keymap.set('n', '<leader>f', function()
    vim.lsp.buf.format({ async = true })
end, { noremap = true })

-- Diagnostic display settings
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>d", function()
    local current_config = vim.diagnostic.config() or {}
    local new_state = not (current_config.virtual_text ~= false)
    vim.diagnostic.config({ virtual_text = new_state })
end, { noremap = true })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { noremap = true })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { noremap = true })
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { noremap = true })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { noremap = true })

-- Disable telemetry for copilot.vim
vim.g.copilot_lsp_settings = {
    telemetry = {
        telemetryLevel = "off",
    },
}

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
