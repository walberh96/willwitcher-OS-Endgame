return {
  "NvChad/nvim-colorizer.lua",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("colorizer").setup({
      filetypes = { "*" }, -- todos los archivos
      user_default_options = {
        RGB      = true,  -- #RGB
        RRGGBB   = true,  -- #RRGGBB
        names    = true,  -- "red", "blue", etc.
        RRGGBBAA = true,  -- #RRGGBBAA
        AARRGGBB = true,
        rgb_fn   = true,  -- rgb(), rgba()
        hsl_fn   = true,  -- hsl(), hsla()
        css      = true,  -- soporta colores CSS
        css_fn   = true,  -- soporta funciones CSS
        mode     = "background", -- pinta el fondo (puede ser "foreground")
      },
    })
  end,
}

