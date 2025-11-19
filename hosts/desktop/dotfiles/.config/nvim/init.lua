-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Common mapping opts (you were using `opts` without defining it)
local opts = { noremap = true, silent = true }

-- Better select/copy/paste mappings
vim.keymap.set('v', '<C-c>', '"+y', opts)
vim.keymap.set('v', '<C-v>', '"+p', opts)
vim.keymap.set('n', '<C-a>', 'ggVG', opts) -- select all
vim.keymap.set("n", "<C-n>", "<cmd>Neotree toggle<CR>", { silent = true, noremap = true })
vim.keymap.set("n", "<leader>ff", function() require("telescope.builtin").find_files({ hidden = true }) end,
    { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", function() require("telescope.builtin").live_grep() end, { desc = "Live grep" })

vim.keymap.set("i", "<C-Space>", "<C-x><C-o>", { silent = true })
vim.keymap.set("i", "<C-@>", "<C-x><C-o>", { silent = true }) -- some terminals send C-@

-- Improve completion UX
vim.opt.completeopt = { "menu", "menuone", "noselect" }

vim.opt.termguicolors = true

-- Set inline relative numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Setup lazy.nvim
require("lazy").setup("plugins", {
    -- put the lockfile in a writable dir (data or state are fine)
    lockfile = vim.fn.stdpath("data") .. "/lazy/lazy-lock.json",
    -- lockfile = vim.fn.stdpath("state") .. "/lazy/lazy-lock.json", -- alternative
})
