return {
  "nvimdev/dashboard-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local db = require("dashboard")

    db.setup({
      theme = "doom",

      config = {      
	center = {
          {
            icon = "  ",
            desc = "New file                             ",
            key = "n",
            action = "enew",
          },
          {
            icon = "  ",
            desc = "Find file (Telescope)                ",
            key = "f",
            action = "Telescope find_files",
          },
          {
            icon = "󰭎  ",
            desc = "Recent files (Telescope)             ",
            key = "r",
            action = "Telescope oldfiles",
          },
          {
            icon = "󱄊  ",
            desc = "Quit Neovim                          ",
            key = "q",
            action = "qa",
          },
        },

        footer = {
          "",
          "WillwitcherOS",
          "",
        },
      },
    })
  end,
}

