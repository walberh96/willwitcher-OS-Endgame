{ config, pkgs, lib, ... }:

# Zed editor module for Home Manager (WillWitcherOS style)
# - No dependencies on yazi.
# - Optional Stylix-driven theming (toggleable).
# - Optional font management (toggleable).
#
# How to enable (in your home.nix):
#   imports = [ (inputs.self + /modules/home-manager/zed.nix) ];
#   willwitcher.zed.enable = true;
#   # Optional toggles:
#   # willwitcher.zed.themeFromStylix = false;  # disable Stylix theme generation for Zed
#   # willwitcher.zed.manageFonts     = true;   # let this module set Zed font family/sizes

let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.willwitcher.zed;
in
{
  options.willwitcher.zed = {
    # Main switch for this module
    enable = mkEnableOption "Enable Zed editor with WillWitcher defaults";

    # If true, use Stylix to generate/provide a Zed theme so Zed follows your Stylix palette.
    themeFromStylix = mkOption {
      type = types.bool;
      default = true;
      description = "When true, enable stylix.targets.zed so Zed follows Stylix theming.";
    };

    # If true, set font families/sizes here. If false, inherit system/Stylix choices.
    manageFonts = mkOption {
      type = types.bool;
      default = false;
      description = "Manage Zed font family and sizes in this module instead of inheriting from system.";
    };
  };

  config = mkIf cfg.enable {
    # CLI tools used by tasks / language servers (no yazi here)
    home.packages = with pkgs; [
      gitu
      nixd
    ];

    # Optional: let Stylix provide a Zed theme (auto-updates with your Stylix changes)
    stylix.targets.zed.enable = cfg.themeFromStylix;

    programs.zed-editor = {
      enable = true;

      # User preferences. We keep them color-agnostic so Stylix (or Zed theme) leads the look.
      userSettings =
        # Fonts are only managed if you explicitly opt in via willwitcher.zed.manageFonts = true;
        (mkIf cfg.manageFonts {
          buffer_font_family = "FiraCode Nerd Font";  # editor text
          buffer_font_size   = 24.0;
          ui_font_family     = "Fira Sans";           # UI (tabs, panels, tree)
          ui_font_size       = 16.0;
        })
        // {
          # Cursor/Session/UI ergonomics
          cursor_blink = false;

          session.restore_unsaved_buffers = false;
          restore_on_startup = "none";

          toolbar = {
            code_actions  = true;
            agent_review  = false;
            breadcrumbs   = true;
          };

          minimap = {
            max_width_columns = 80;
            thumb = "always";
            show  = "always";
          };

          # Search behavior
          search = { regex = false; };
          use_smartcase_search = true;

          close_on_file_delete = true;

          file_finder.modal_max_width = "large";
          gutter.min_line_number_digits = 4;

          # Show trailing whitespaces only (keeps view clean)
          show_whitespaces = "trailing";

          tab_bar = {
            show = false;
            show_nav_history_buttons = false;
          };

          # Privacy & updates
          use_system_prompts      = false;
          use_system_path_prompts = false;
          auto_update             = false;
          telemetry = {
            diagnostics = false;
            metrics     = false;
          };

          # Editing defaults
          tab_size   = 2;
          disable_ai = true;

          agent = {
            button = false;
            model_parameters = [ ];
          };

          git_panel.button = false;
          project_panel.starts_open = false;

          active_pane_modifiers = {
            border_size      = 0.0;
            inactive_opacity = 1.0;
          };

          bottom_dock_layout = "contained";

          title_bar = {
            show_menus       = false;
            show_branch_icon = true;
          };

          preview_tabs.enable_preview_from_file_finder = false;

          tabs = {
            file_icons        = true;
            git_status        = true;
            show_close_button = "always";
            activate_on_close = "left_neighbour";
          };

          # Disable Prettier integration by default (can enable per-project)
          prettier.allowed = false;

          # Modal editing + base keymap preference
          vim_mode    = true;
          base_keymap = "Emacs";

          # Icon theme remains default (coloring comes from the active theme)
          icon_theme = "Zed (Default)";
        };

      # Keymaps: removed any yazi-related bindings. Kept gitu shortcut and navigation.
      userKeymaps = [
        # Global: open command palette
        {
          context = "";
          bindings."alt-x" = "command_palette::Toggle";
        }

        # Main workspace navigation and helpers (VimControl or when no editor/menu/terminal is focused)
        {
          context = "VimControl || (!Editor && !menu && !Terminal)";
          bindings = {
            # Save
            "ctrl-x ctrl-s"       = "workspace::Save";
            "ctrl-x ctrl-shift-s" = "workspace::SaveAll";

            # Split panes
            "space w v" = "pane::SplitVertical";
            "space w V" = "pane::SplitVertical";
            "space w h" = "pane::SplitHorizontal";
            "space w H" = "pane::SplitHorizontal";

            # File/project
            "space p f" = "file_finder::Toggle";
            "space p p" = "projects::OpenRecent";

            # Git TUI (gitu) task
            "space g g" = [
              "task::Spawn"
              { task_name = "gitu"; }
            ];

            # Pane navigation
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-l" = "workspace::ActivatePaneRight";
            "ctrl-j" = "workspace::ActivatePaneDown";
            "ctrl-k" = "workspace::ActivatePaneUp";

            # Close current item/pane
            "space w d" = "pane::CloseActiveItem";

            # Cycle panel tabs
            "space b p" = "panel::PreviousPanelTab";
            "space b n" = "panel::NextPanelTab";

            # Toggle integrated terminal panel
            "alt-z" = "terminal_panel::Toggle";
          };
        }

        # Terminal context: keep the same toggle
        {
          context = "Terminal";
          bindings."alt-z" = "terminal_panel::Toggle";
        }

        # Example: insert-mode-only context (empty so you can add later)
        {
          context  = "Editor && vim_mode == insert";
          bindings = { };
        }
      ];

      # Tasks: removed yazi; kept gitu
      userTasks = [
        {
          label  = "gitu";
          command = "gitu || {git init && gitu}";
          reveal = "always";
          reveal_target = "center";
          allow_concurrent_runs = false;
          use_new_terminal      = false;
          hide = "on_success";
        }
      ];

      # Language/feature extensions (unchanged; safe to keep)
      extensions = [
        "nix" "gdscript" "git_firefly" "toml" "xml" "svelte" "vue" "scss" "make"
        "dockerfile" "docker-compose" "hyprlang" "java" "lua" "r" "kotlin"
        "haskell" "perl" "fortran" "ruby" "org"
      ];
    };
  };
}
