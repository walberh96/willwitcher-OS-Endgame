{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.willwitcher.nvim;

  vp = pkgs.vimPlugins;
  # Optional plugins (channel-dependent)
  bufferline     = vp.bufferline-nvim or null;
  whichKey       = vp.which-key-nvim or null;
  ccc            = vp.ccc-nvim or null;
  telescope      = vp.telescope-nvim or null;
  telescopeFzf   = vp.telescope-fzf-native-nvim or null;
  telescopeUiSel = vp.telescope-ui-select-nvim or null;
  snacks         = vp.snacks-nvim or null;
  smearCursor    = vp.smear-cursor-nvim or null;

  startOptional = ps: lib.flatten (map (p: lib.optional (p != null) p) ps);
in
{
  options.willwitcher.nvim.enable = lib.mkEnableOption "NVF-based Neovim setup (WillWitcher)";

  # Import NVF here (do not import it elsewhere)
  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  config = lib.mkIf cfg.enable {
    # Requires Stylix HM to be imported somewhere in your home.nix
    stylix.targets.nvf.enable = true;

    # CLI tools used by Telescope/DAP/etc. (add to what you already have)
    home.packages = with pkgs; [
      ripgrep fd fzf
      lldb
      deno
      # nodePackages.prettier  # Use this instead of Deno if you prefer
    ];

    programs.nvf = {
      enable = true;
      defaultEditor = true;
      enableManpages = true;

      settings.vim = {
        viAlias = true;
        vimAlias = true;

        ############################################
        ## FILE EXPLORER: nvim-tree (left side)
        ############################################
        filetree.nvimTree = {
          enable = true;
          setupOpts.view.side = "left";
        };

        ############################################
        ## GIT: neogit + gitsigns (blame OFF by default)
        ############################################
        git = {
          neogit.enable = true;
          gitsigns.enable = true;
        };

        ############################################
        ## MARKDOWN: render-markdown (no LSP)
        ############################################
        languages.markdown = {
          enable = true;
          lsp.enable = false;          # avoid lspconfig warning
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
        ## Extra plugins (via nixpkgs, optional by channel)
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
        ## Lua config (keymaps + light setups)
        ############################################
        luaConfigRC = {
          # --- LSP: define a global default_on_attach early (fixes ON_ATTACH_ERROR) ---
          _000_lsp_pre = ''
            -- Provide a global handler some setups expect.
            function _G.default_on_attach(client, bufnr)
              local function map(mode, lhs, rhs, desc)
                vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, noremap = true, desc = desc })
              end

              -- Basic LSP keymaps
              map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
              map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
              map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
              map('n', 'gr', vim.lsp.buf.references, 'List references')
              map('n', 'K',  vim.lsp.buf.hover, 'Hover docs')
              map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
              map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')
              map('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, 'Format buffer')
            end
          '';

          # Explorer toggle (Ctrl+n)
          nvimtree = ''
            vim.keymap.set('n', '<C-n>', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle file explorer' })
          '';

          # Bufferline + buffer navigation
          bufferline = ''
            pcall(function()
              require('bufferline').setup({})
              -- Tab / Shift-Tab to cycle buffers
              vim.keymap.set('n', '<Tab>', '<cmd>BufferLineCycleNext<CR>')
              vim.keymap.set('n', '<S-Tab>', '<cmd>BufferLineCyclePrev<CR>')
              -- <leader>1..9 to jump to buffer N
              for i = 1, 9 do
                vim.keymap.set('n', '<leader>' .. i, '<cmd>BufferLineGoToBuffer ' .. i .. '<CR>')
              end
            end)
          '';

          # which-key
          whichkey = ''
            pcall(function()
              require('which-key').setup({})
            end)
          '';

          # ccc (color picker) + inline previews
          ccc = ''
            pcall(function()
              require('ccc').setup({})
              -- Enable inline color previews
              vim.cmd('CccHighlighterEnable')
              -- Keybindings
              vim.keymap.set('n', '<leader>cp', '<cmd>CccPick<CR>', { desc = 'Color Picker (ccc)' })
              vim.keymap.set('n', '<leader>ch', '<cmd>CccHighlighterToggle<CR>', { desc = 'Toggle color preview (ccc)' })
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
              vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>', { desc = 'Find files' })
              vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', { desc = 'Live grep' })
              vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>',    { desc = 'Buffers' })
              vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<CR>',  { desc = 'Help tags' })
            end)
          '';

          # Gitsigns: blame OFF by default (toggle manually)
          gitsigns = ''
            pcall(function()
              require('gitsigns').setup({
                current_line_blame = false,
                current_line_blame_opts = { delay = 400 },
                current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
              })
            end)
          '';

          # Neogit in floating window + keybinding
          neogit = ''
            pcall(function()
              vim.keymap.set('n', '<leader>gg', function()
                require('neogit').open({ kind = 'floating' })
              end, { desc = 'Neogit (floating)' })
            end)
          '';

          # Snacks (default setup)
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

