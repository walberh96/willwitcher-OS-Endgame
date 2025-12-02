-- lua/plugins/snacks.lua
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  ---@type snacks.Config
  opts = {
    dashboard     = { enabled = true },
    explorer      = { enabled = true },
    picker        = { enabled = true },
    terminal      = { enabled = true },
    lazygit       = { enabled = true },

    notifier      = { enabled = true, timeout = 3000 },
    bigfile       = { enabled = true },
    quickfile     = { enabled = true },
    indent        = { enabled = true },
    scope         = { enabled = true },
    scroll        = { enabled = true },
    statuscolumn  = { enabled = true },
    words         = { enabled = true },
    zen           = { enabled = true },
  },

  keys = {
    -- Explorer
    { "<leader>e",  function() Snacks.explorer() end,                 desc = "File explorer" },

    -- Pickers
    { "<leader>ff", function() Snacks.picker.files() end,             desc = "Find files" },
    { "<leader>fg", function() Snacks.picker.grep() end,              desc = "Grep" },
    { "<leader>fb", function() Snacks.picker.buffers() end,           desc = "Buffers" },
    { "<leader>fr", function() Snacks.picker.recent() end,            desc = "Recent files" },

    -- Git UI (Neogit replacement)
    { "<leader>gg", function() Snacks.lazygit() end,                  desc = "Lazygit" },

    -- Terminal (Toggleterm replacement)
    { "<C-\\>",     function() Snacks.terminal() end,
      mode = { "n", "t" },                                            desc = "Toggle terminal" },

    -- Zen / notifications
    { "<leader>z",  function() Snacks.zen() end,                      desc = "Zen mode" },
    { "<leader>un", function() Snacks.notifier.hide() end,            desc = "Dismiss notifications" },
    { "<leader>nh", function() Snacks.notifier.show_history() end,    desc = "Notification history" },
  },
}

