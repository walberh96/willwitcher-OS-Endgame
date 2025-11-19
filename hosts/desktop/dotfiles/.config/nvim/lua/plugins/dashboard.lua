return {
  "nvimdev/dashboard-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local db = require("dashboard")

    db.setup({
      theme = "doom", -- también puedes usar "hyper"

      config = {
        header = {
          "",
          "██╗    ██╗██╗██╗     ██╗    ██╗██╗████████╗ ██████╗██╗  ██╗███████╗██████╗ ",
          "██║    ██║██║██║     ██║    ██║██║╚══██╔══╝██╔════╝██║ ██╔╝██╔════╝██╔══██╗",
          "██║ █╗ ██║██║██║     ██║ █╗ ██║██║   ██║   ██║     █████╔╝ █████╗  ██████╔╝",
          "██║███╗██║██║██║     ██║███╗██║██║   ██║   ██║     ██╔═██╗ ██╔══╝  ██╔══██╗",
          "╚███╔███╔╝██║███████╗╚███╔███╔╝██║   ██║   ╚██████╗██║  ██╗███████╗██║  ██║",
          " ╚══╝╚══╝ ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝",
          "",
          "                          WillwitcherOS • Neovim",
          "",
        },

        center = {
          {
            icon = "  ",
            desc = "Nuevo archivo                         ",
            key = "n",
            action = "enew",
          },
          {
            icon = "  ",
            desc = "Buscar archivo (Telescope)            ",
            key = "f",
            action = "Telescope find_files",
          },
          {
            icon = "  ",
            desc = "Archivos recientes (Telescope)        ",
            key = "r",
            action = "Telescope oldfiles",
          },
          {
            icon = "  ",
            desc = "Editar config de Neovim               ",
            key = "c",
            action = "edit ~/.config/nvim/init.lua",
          },
          {
            icon = "󰦕  ",
            desc = "Salir de Neovim                       ",
            key = "q",
            action = "qa",
          },
        },

        footer = {
          "",
          "💜 Disfruta tu setup, Will",
          "",
        },
      },
    })
  end,
}

