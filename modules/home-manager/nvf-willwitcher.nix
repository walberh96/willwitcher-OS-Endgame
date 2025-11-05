{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.willwitcher.nvim;

  vp = pkgs.vimPlugins;
  # Plugins que podrían no existir en tu canal: se vuelven opcionales
  bufferline      = vp.bufferline-nvim or null;
  whichKey        = vp.which-key-nvim or null;
  ccc             = vp.ccc-nvim or null;
  telescope       = vp.telescope-nvim or null;
  telescopeFzf    = vp.telescope-fzf-native-nvim or null;
  telescopeUiSel  = vp.telescope-ui-select-nvim or null;
  snacks          = vp.snacks-nvim or null;
  smearCursor     = vp.smear-cursor-nvim or null;

  startOptional = ps: lib.flatten (map (p: lib.optional (p != null) p) ps);
in
{
  options.willwitcher.nvim.enable = lib.mkEnableOption "NVF-based Neovim setup (WillWitcher)";

  # Importa el módulo de NVF aquí (no lo importes en otro sitio)
  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  config = lib.mkIf cfg.enable {
    # Requiere que ya hayas importado Stylix HM en algún lugar de tu home.nix
    stylix.targets.nvf.enable = true;

    # Binarios que usa Telescope/DAP/etc. (se suman a los que ya tengas)
    home.packages = with pkgs; [
      ripgrep fd fzf
      lldb
      # Opcionales (los tienes en tu lista, por si quieres formatear .md con deno/prettier)
      deno
      # nodePackages.prettier
    ];

    programs.nvf = {
      enable = true;
      defaultEditor = true;
      enableManpages = true;

      settings.vim = {
        viAlias = true;
        vimAlias = true;

        ############################################
        ## FILE EXPLORER: nvim-tree (izquierda, oculto)
        ############################################
        filetree.nvimTree = {
          enable = true;
          setupOpts.view.side = "left";
        };

        ############################################
        ## GIT: neogit + gitsigns (blame OFF)
        ############################################
        git = {
          neogit.enable = true;
          gitsigns.enable = true;
        };

        ############################################
        ## MARKDOWN: render-markdown (sin LSP)
        ############################################
        languages.markdown = {
          enable = true;
          lsp.enable = false;          # -> sin lspconfig warning
          format.enable = true;
          extensions.render-markdown-nvim.enable = true;
        };

        ############################################
        ## RUST: LSP/format/DAP
        ############################################
        languages.rust = {
          enable = true;
          lsp.enable = true;
          format.enable = true;
          dap.enable = true;
        };

        ############################################
        ## PLUGINS extra (vía nixpkgs, opcionales por canal)
        ############################################
        startPlugins = startOptional [
          bufferline
          whichKey
          ccc
          telescope
          telescopeFzf
          telescopeUiSel
          snacks
          smearCursor
        ];

        ############################################
        ## Lua config (keymaps + setups ligeros)
        ############################################
        luaConfigRC = {
          # Explorer toggle (Ctrl+n) y ajustes
          nvimtree = ''
            vim.keymap.set('n', '<C-n>', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle file explorer' })
          '';

          # Bufferline + navegación de buffers
          bufferline = ''
            pcall(function()
              require('bufferline').setup({})
              -- Tab / Shift-Tab para navegar buffers
              vim.keymap.set('n', '<Tab>', '<cmd>BufferLineCycleNext<CR>')
              vim.keymap.set('n', '<S-Tab>', '<cmd>BufferLineCyclePrev<CR>')
              -- <leader>1..9 para saltar a buffer N
              for i = 1, 9 do
                vim.keymap.set('n', '<leader>' .. i, '<cmd>BufferLineGoToBuffer ' .. i .. '<CR>')
              end
            end)
          '';

          # which-key (descubrimiento de teclas)
          whichkey = ''
            pcall(function()
              require('which-key').setup({})
            end)
          '';

          # ccc (color picker) + entrada sugerida en which-key
          ccc = ''
            pcall(function()
              require('ccc').setup({})
              -- Ejemplo: <leader>cp para abrir el picker
              vim.keymap.set('n', '<leader>cp', '<cmd>CccPick<CR>', { desc = 'Color Picker (ccc)' })
            end)
          '';

          # Telescope + bindings
          telescope = ''
            pcall(function()
              local ok, telescope = pcall(require, 'telescope')
              if ok then
                telescope.setup({})
                pcall(telescope.load_extension, 'fzf')
                pcall(telescope.load_extension, 'ui-select')
              end
              -- Keys estándar
              vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>', { desc = 'Find files' })
              vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', { desc = 'Live grep' })
              vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>',    { desc = 'Buffers' })
              vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<CR>',  { desc = 'Help tags' })
            end)
          '';

          # Gitsigns: blame en línea -> OFF por defecto (toggle manual)
          gitsigns = ''
            pcall(function()
              require('gitsigns').setup({
                current_line_blame = false,
                current_line_blame_opts = { delay = 400 },
                current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
              })
            end)
          '';

          # Neogit en floating + keybinding
          neogit = ''
            pcall(function()
              vim.keymap.set('n', '<leader>gg', function()
                require('neogit').open({ kind = 'floating' })
              end, { desc = 'Neogit (floating)' })
            end)
          '';

          # Snacks (modular) - solo setup por defecto; ajustamos módulos luego si quieres
          snacks = ''
            pcall(function()
              require('snacks').setup({})
            end)
          '';

          # Cursor warp (smear-cursor)
          smearcursor = ''
            pcall(function()
              require('smear_cursor').setup({})
            end)
          '';
        };
      };
    };
  };
}

