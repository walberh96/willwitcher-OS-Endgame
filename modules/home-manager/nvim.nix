{ config, lib, pkgs, ... }:

# Neovim (Home Manager) — WillWitcherOS style
#
# What this module does:
# - Enables Neovim via Home Manager and can make it your default $EDITOR.
# - Provides a sane, modern plugin stack (LSP, treesitter, completion, UI).
# - Adds common LSP servers and CLI deps (ripgrep, fd) declaratively.
# - Keeps color ownership outside (Stylix/terminal). We don't hardcode a theme.
#   (You can enable a theme provider below if you want.)
#
# How to enable in your home.nix:
#   imports = [ (inputs.self + /modules/home-manager/nvim.nix) ];
#   willwitcher.nvim.enable = true;
#
# Optional toggles (see options below for details):
#   willwitcher.nvim.defaultEditor = true;
#   willwitcher.nvim.viAlias       = true;
#   willwitcher.nvim.vimAlias      = true;
#   willwitcher.nvim.plugins.themeProvider = "none"; # or "catppuccin"
#   willwitcher.nvim.lsp.enable.lua   = true;
#   willwitcher.nvim.lsp.enable.nix   = true;
#   willwitcher.nvim.lsp.enable.python= true;
#   willwitcher.nvim.lsp.enable.rust  = true;
#   willwitcher.nvim.lsp.enable.bash  = true;
#   willwitcher.nvim.lsp.enable.web   = true;  # html/css/json from vscode-langservers-extracted
#   willwitcher.nvim.lsp.enable.yaml  = true;
#   willwitcher.nvim.lsp.enable.toml  = true;
#
# Notes:
# - We configure Neovim in Lua via `extraLuaConfig`.
# - Telescope relies on `ripgrep` and `fd` which we include in `extraPackages`.
# - If you prefer a theme: set plugins.themeProvider = "catppuccin". Otherwise
#   Neovim inherits your terminal (Kitty) colors, which Stylix already controls.

let
  inherit (lib) mkEnableOption mkIf mkOption types optionals;

  cfg = config.willwitcher.nvim;

  # Build the list of LSP tool packages based on toggles
  lspPkgs = with pkgs;
    (optionals cfg.lsp.enable.lua   [ lua-language-server ]) ++
    (optionals cfg.lsp.enable.nix   [ nil ]) ++
    (optionals cfg.lsp.enable.python[ pyright ]) ++
    (optionals cfg.lsp.enable.rust  [ rust-analyzer ]) ++
    (optionals cfg.lsp.enable.bash  [ bash-language-server ]) ++
    (optionals cfg.lsp.enable.web   [ vscode-langservers-extracted ]) ++
    (optionals cfg.lsp.enable.yaml  [ yaml-language-server ]) ++
    (optionals cfg.lsp.enable.toml  [ taplo ]);

  # Plugin list assembled from toggles
  pluginList =
    with pkgs.vimPlugins;
      []
      # Core UX
      ++ optionals cfg.plugins.whichKey  [ which-key-nvim ]
      ++ optionals cfg.plugins.lualine   [ lualine-nvim ]
      ++ optionals cfg.plugins.gitsigns  [ gitsigns-nvim ]
      ++ optionals cfg.plugins.comment   [ comment-nvim ]
      ++ optionals cfg.plugins.autopairs [ nvim-autopairs ]
      ++ optionals cfg.plugins.indent    [ indent-blankline-nvim ]
      # LSP + completion
      ++ optionals cfg.plugins.lsp       [ nvim-lspconfig ]
      ++ optionals cfg.plugins.cmp       [ nvim-cmp cmp-nvim-lsp cmp-buffer cmp-path luasnip friendly-snippets ]
      # Treesitter
      ++ optionals cfg.plugins.treesitter[ nvim-treesitter ]
      # Fuzzy finder
      ++ optionals cfg.plugins.telescope [ telescope-nvim plenary-nvim ]
      # Optional theme provider (kept off by default so Stylix/terminal rules)
      ++ (if cfg.plugins.themeProvider == "catppuccin" then [ catppuccin-nvim ] else []);

  # Lua configuration string for Neovim (single source of truth)
  luaCfg = ''
    -- General editor settings
    vim.g.mapleader = ' '
    vim.opt.termguicolors = true
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.signcolumn = "yes"
    vim.opt.cursorline = true
    vim.opt.updatetime = 300
    vim.opt.timeoutlen = 400
    vim.opt.splitright = true
    vim.opt.splitbelow = true

    -- Which-key (key-hint popups)
    ${lib.optionalString cfg.plugins.whichKey ''
      require("which-key").setup({})
    ''}

    -- Statusline
    ${lib.optionalString cfg.plugins.lualine ''
      require("lualine").setup({
        options = { theme = 'auto', icons_enabled = true, globalstatus = true }
      })
    ''}

    -- Git signs
    ${lib.optionalString cfg.plugins.gitsigns ''
      require("gitsigns").setup({})
    ''}

    -- Comments
    ${lib.optionalString cfg.plugins.comment ''
      require("Comment").setup({})
    ''}

    -- Autopairs
    ${lib.optionalString cfg.plugins.autopairs ''
      require("nvim-autopairs").setup({})
    ''}

    -- Indentation guides
    ${lib.optionalString cfg.plugins.indent ''
      require("ibl").setup({})
    ''}

    -- Telescope
    ${lib.optionalString cfg.plugins.telescope ''
      local ok_telescope, telescope = pcall(require, "telescope")
      if ok_telescope then telescope.setup({}) end
      -- Convenience mappings
      local map = vim.keymap.set
      map('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { desc = 'Telescope: find files' })
      map('n', '<leader>fg', '<cmd>Telescope live_grep<cr>',  { desc = 'Telescope: live grep' })
      map('n', '<leader>fb', '<cmd>Telescope buffers<cr>',    { desc = 'Telescope: buffers' })
      map('n', '<leader>fh', '<cmd>Telescope help_tags<cr>',  { desc = 'Telescope: help' })
    ''}

    -- Treesitter (highlight only; grammars via nixpkgs plugins or TS update)
    ${lib.optionalString cfg.plugins.treesitter ''
      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        indent = { enable = true },
      })
    ''}

    -- Completion (nvim-cmp + luasnip)
    ${lib.optionalString cfg.plugins.cmp ''
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]     = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"]   = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    ''}

    -- LSP servers (Neovim 0.11+ native API, no lspconfig, no deprecations)
    ${lib.optionalString cfg.plugins.lsp ''
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end

      -- Build server list from your toggles
      local servers = {}
      ${lib.optionalString cfg.lsp.enable.lua    ''table.insert(servers, "lua_ls")''}
      ${lib.optionalString cfg.lsp.enable.nix    ''table.insert(servers, "nil_ls")''}
      ${lib.optionalString cfg.lsp.enable.python ''table.insert(servers, "pyright")''}
      ${lib.optionalString cfg.lsp.enable.rust   ''table.insert(servers, "rust_analyzer")''}
      ${lib.optionalString cfg.lsp.enable.bash   ''table.insert(servers, "bashls")''}
      ${lib.optionalString cfg.lsp.enable.web    ''for _,s in ipairs({ "html", "cssls", "jsonls" }) do table.insert(servers, s) end''}
      ${lib.optionalString cfg.lsp.enable.yaml   ''table.insert(servers, "yamlls")''}
      ${lib.optionalString cfg.lsp.enable.toml   ''table.insert(servers, "taplo")''}

      -- Command map (bin names come from your extraPackages)
      local cmd_by_server = {
        lua_ls         = { "lua-language-server" },
        nil_ls         = { "nil" },
        pyright        = { "pyright-langserver", "--stdio" },
        rust_analyzer  = { "rust-analyzer" },
        bashls         = { "bash-language-server", "start" },
        html           = { "vscode-html-language-server",  "--stdio" },
        cssls          = { "vscode-css-language-server",   "--stdio" },
        jsonls         = { "vscode-json-language-server",  "--stdio" },
        yamlls         = { "yaml-language-server",         "--stdio" },
        taplo          = { "taplo", "lsp", "stdio" },
      }

      for _, server in ipairs(servers) do
        local cfg = {
          name = server,                        -- MUST be a plain string
          cmd = cmd_by_server[server],
          capabilities = capabilities,
          -- root_dir = vim.fn.getcwd(),        -- optional: set a root rule if you want
        }

        if server == "lua_ls" then
          cfg.settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace   = { checkThirdParty = false },
            }
          }
        end

        -- Start client (native API; no deprecated framework)
        vim.lsp.start(cfg)
      end

      -- Basic LSP keymaps
      local map = vim.keymap.set
      local o = { noremap = true, silent = true }
      map("n", "gd", vim.lsp.buf.definition, o)
      map("n", "gr", vim.lsp.buf.references, o)
      map("n", "K",  vim.lsp.buf.hover,      o)
      map("n", "<leader>rn", vim.lsp.buf.rename, o)
      map("n", "<leader>ca", vim.lsp.buf.code_action, o)
      map("n", "<leader>e",  vim.diagnostic.open_float, o)
      map("n", "[d", vim.diagnostic.goto_prev, o)
      map("n", "]d", vim.diagnostic.goto_next, o)
    ''}

  '';
in
{
  options.willwitcher.nvim = {
    enable = mkEnableOption "Enable Neovim (managed by Home Manager)";

    defaultEditor = mkOption {
      type = types.bool;
      default = true;
      description = "Set Neovim as default editor ($EDITOR) via HM.";
    };

    viAlias = mkOption {
      type = types.bool;
      default = true;
      description = "Provide `vi` alias that launches Neovim.";
    };

    vimAlias = mkOption {
      type = types.bool;
      default = true;
      description = "Provide `vim` alias that launches Neovim.";
    };

    plugins = {
      whichKey  = mkOption { type = types.bool; default = true;  description = "Enable which-key.nvim"; };
      lualine   = mkOption { type = types.bool; default = true;  description = "Enable lualine statusline"; };
      gitsigns  = mkOption { type = types.bool; default = true;  description = "Enable gitsigns.nvim"; };
      comment   = mkOption { type = types.bool; default = true;  description = "Enable Comment.nvim"; };
      autopairs = mkOption { type = types.bool; default = true;  description = "Enable nvim-autopairs"; };
      indent    = mkOption { type = types.bool; default = true;  description = "Enable indent guides (indent-blankline)"; };
      telescope = mkOption { type = types.bool; default = true;  description = "Enable telescope.nvim"; };
      treesitter= mkOption { type = types.bool; default = true;  description = "Enable nvim-treesitter"; };
      lsp       = mkOption { type = types.bool; default = true;  description = "Enable nvim-lspconfig"; };
      cmp       = mkOption { type = types.bool; default = true;  description = "Enable nvim-cmp + luasnip"; };

      themeProvider = mkOption {
        type = types.enum [ "none" "catppuccin" ];
        default = "none";
        description = "Optional theme provider inside Neovim. Keep 'none' to let Stylix/terminal drive colors.";
      };
    };

    lsp.enable = {
      lua    = mkOption { type = types.bool; default = true;  description = "Lua LSP (lua-language-server)"; };
      nix    = mkOption { type = types.bool; default = true;  description = "Nix LSP (nil)"; };
      python = mkOption { type = types.bool; default = false; description = "Python LSP (pyright)"; };
      rust   = mkOption { type = types.bool; default = false; description = "Rust LSP (rust-analyzer)"; };
      bash   = mkOption { type = types.bool; default = true;  description = "Bash LSP (bash-language-server)"; };
      web    = mkOption { type = types.bool; default = false; description = "Web LSPs (html, cssls, jsonls)"; };
      yaml   = mkOption { type = types.bool; default = true;  description = "YAML LSP (yaml-language-server)"; };
      toml   = mkOption { type = types.bool; default = true;  description = "TOML LSP (taplo)"; };
    };
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = cfg.defaultEditor;
      viAlias = cfg.viAlias;
      vimAlias = cfg.vimAlias;

      plugins = pluginList;

      extraPackages = with pkgs; [
        ripgrep
        fd
      ] ++ lspPkgs;

      # Single Lua blob with all config; zero dotfiles needed.
      extraLuaConfig = luaCfg;
    };
  };
}
