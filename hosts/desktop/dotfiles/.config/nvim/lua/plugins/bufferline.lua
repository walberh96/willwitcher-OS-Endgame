-- lua/plugins/bufferline.lua
return {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
        { "<Tab>",      "<cmd>BufferLineCycleNext<CR>",   desc = "Next buffer" },
        { "<S-Tab>",    "<cmd>BufferLineCyclePrev<CR>",   desc = "Prev buffer" },
        { "<A-l>",      "<cmd>BufferLineMoveNext<CR>",    desc = "Move buffer right" },
        { "<A-h>",      "<cmd>BufferLineMovePrev<CR>",    desc = "Move buffer left" },
        { "<leader>bp", "<cmd>BufferLinePick<CR>",        desc = "Pick buffer" },
        { "<leader>bc", "<cmd>bdelete<CR>",               desc = "Close buffer" },
        { "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", desc = "Close others" },
        { "<leader>br", "<cmd>BufferLineCloseRight<CR>",  desc = "Close right" },
        { "<leader>bl", "<cmd>BufferLineCloseLeft<CR>",   desc = "Close left" },
    },
    opts = {
        options = {
            mode = "buffers",   -- VS Code–like: one tab per buffer
            indicator = { style = "underline" },
            diagnostics = "nvim_lsp", -- show LSP error/warn dots per tab
            diagnostics_update_in_insert = false,
            always_show_bufferline = true,
            show_buffer_close_icons = true,
            show_close_icon = false,
            separator_style = "thin", -- try "thin" if you prefer subtle
            hover = { enabled = true, delay = 150, reveal = { "close" } },
            offsets = {
                { filetype = "neo-tree", text = "File Explorer", highlight = "Directory", separator = true },
                { filetype = "NvimTree", text = "File Explorer", highlight = "Directory", separator = true },
            },
            -- Nicely truncate long names instead of overflowing
            max_name_length = 22,
            max_prefix_length = 14,
            truncate_names = true,
        },
    },
    config = function(_, opts)
        -- needed for proper colors
        vim.opt.termguicolors = true
        require("bufferline").setup(opts)
    end,
}
