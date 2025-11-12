return {
    "catppuccin/nvim",  -- Plugin name
    name = "catppuccin", -- You can still specify a name
    priority = 1000, -- Plugin priority
    config = function()
        vim.cmd("colorscheme catppuccin-mocha")
    end
  }