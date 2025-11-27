return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" }, -- icons (nerd fonts)
  event = "VeryLazy",
  config = function()
    require("lualine").setup({
      options = {
        icons_enabled = true,
        -- Si usas catppuccin como colorscheme puedes poner "catppuccin"
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators   = { left = "", right = "" },
        globalstatus = true, -- una sola statusline para toda la ventana
        disabled_filetypes = {
          statusline = { "alpha", "dashboard", "starter" },
        },
      },

      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = {
          {
            "filename",
            path = 1,       -- 0 = nombre, 1 = ruta relativa, 2 = ruta absoluta
            symbols = {
              modified = "",
              readonly = "",
              unnamed  = "[No Name]",
            },
          },
        },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },

      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },

      tabline = {},
      extensions = {}, -- luego puedes añadir: "quickfix", "lazy", "mason", etc.
    })
  end,
}

