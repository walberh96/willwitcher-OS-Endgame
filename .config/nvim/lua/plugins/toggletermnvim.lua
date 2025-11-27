-- lua/plugins/toggleterm.lua
return {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
        -- Toggle bottom terminal from Normal *and* Terminal mode
        { "<C-\\>", "<cmd>ToggleTerm direction=horizontal<CR>", mode = { "n", "t" }, desc = "Toggle terminal (bottom)" },
    },
    opts = {
        open_mapping = [[<c-\>]], -- Ctrl+\ to open/toggle
        direction = "horizontal", -- bottom split like VS Code
        size = 12,            -- height in rows; tweak to taste
        start_in_insert = true,
        shade_terminals = true,
        persist_size = true,
    },
}
