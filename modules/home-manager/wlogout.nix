# modules/home-manager/wlogout.nix
#
# A small Home-Manager module that:
# - Installs wlogout (and hyprlock, since you use it)
# - Generates ~/.config/wlogout/style.css using Stylix Base16 colors (with sane fallbacks)
# - Generates ~/.config/wlogout/layout to wire actions (lock via hyprlock, suspend, reboot, etc.)
# - Exposes a few knobs (columns, lockFirstOnSuspend, extraCss, per-action commands/icons)
#
# Usage:
#   1) Put this file at: modules/home-manager/wlogout.nix
#   2) In your home.nix (or host/home.nix), add:
#        imports = [ ../../modules/home-manager/wlogout.nix ];
#      and configure:
#        willwitcher.wlogout.enable = true;
#   3) (Optional) Add the Waybar button shown at the end of this file.
#
{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption mkIf mkOption types optionalString attrByPath;

  cfg = config.willwitcher.wlogout;

  # --- Palette (Stylix -> Base16). We fall back to a Catppuccin-Mocha-ish set if Stylix is missing ---
  defaultPalette = {
    base00 = "1e1e2e"; # base
    base01 = "181825"; # mantle
    base02 = "313244"; # surface0
    base03 = "45475a"; # surface1
    base04 = "585b70"; # surface2
    base05 = "cdd6f4"; # text
    base06 = "f5e0dc"; # rosewater
    base07 = "b4befe"; # lavender
    base08 = "f38ba8"; # red
    base09 = "fab387"; # peach
    base0A = "f9e2af"; # yellow
    base0B = "a6e3a1"; # green
    base0C = "94e2d5"; # teal
    base0D = "89b4fa"; # blue
    base0E = "cba6f7"; # mauve
    base0F = "f2cdcd"; # flamingo
  };

  # Try to read Stylix colors from config.lib.stylix.colors; fall back otherwise
  stylixColors = attrByPath [ "lib" "stylix" "colors" ] defaultPalette config;

  # Try to read Stylix sans font name; fall back to Inter
  sansFont = attrByPath [ "stylix" "fonts" "sansSerif" "name" ] "Inter" config;

  # Handy alias
  c = stylixColors;

  # Default actions (shell commands). You can override any of these via the module options.
  defaultActions = {
    lock     = "hyprlock";
    suspend  = "hyprlock & sleep 0.4 && systemctl suspend"; # lock first, then suspend
    reboot   = "systemctl reboot";
    poweroff = "systemctl poweroff";
    logout   = "hyprctl dispatch exit 0"; # Hyprland logout; change if you want a different compositor cmd
  };

  # Default glyphs (Nerd Font / Font Awesome-like). These render as large icons on each button.
  defaultIcons = {
    lock     = "";
    suspend  = "";
    reboot   = "";
    poweroff = "";
    logout   = "";
  };

  # Per-action background colors from Base16 (tweak to taste)
  actionBg = {
    lock     = c.base0D; # blue
    suspend  = c.base0B; # green
    reboot   = c.base0A; # yellow
    poweroff = c.base08; # red
    logout   = c.base0C; # teal
  };

  # Build the JSON layout from current options (no comments; wlogout expects plain JSON).
  layoutJson = builtins.toJSON {
    columns = cfg.columns;
    actions = [
      { label = cfg.icons.lock;     action = cfg.actions.lock;     id = "lock";     }
      { label = cfg.icons.suspend;  action = cfg.actions.suspend;  id = "suspend";  }
      { label = cfg.icons.reboot;   action = cfg.actions.reboot;   id = "reboot";   }
      { label = cfg.icons.poweroff; action = cfg.actions.poweroff; id = "poweroff"; }
      { label = cfg.icons.logout;   action = cfg.actions.logout;   id = "logout";   }
    ];
  };

  # CSS alpha for the backdrop. We use hex alpha (E6 ~ 90%). Tweak in options if you want.
  alphaHex = cfg.cssBackdropAlphaHex;
in
{
  options.willwitcher.wlogout = {
    enable = mkEnableOption "Styleable power/logout menu using wlogout + Stylix colors";

    # Grid columns for the layout JSON
    columns = mkOption {
      type = types.int;
      default = 5;
      description = "Number of columns in the wlogout grid layout.";
    };

    # If true, we generate CSS from the Stylix palette. Otherwise we still generate
    # a neutral theme using the fallback palette above.
    useStylixColors = mkOption {
      type = types.bool;
      default = true;
      description = "Use Stylix palette (if available) for wlogout CSS.";
    };

    # When true, 'suspend' first launches hyprlock, waits a moment, then suspends.
    lockFirstOnSuspend = mkOption {
      type = types.bool;
      default = true;
      description = "Lock the session with hyprlock before suspending.";
    };

    # Per-action shell commands (override any if you prefer different behavior).
    actions = mkOption {
      type = types.submodule {
        options = {
          lock     = mkOption { type = types.str; default = defaultActions.lock;     description = "Command executed for the Lock button."; };
          suspend  = mkOption { type = types.str; default = defaultActions.suspend;  description = "Command executed for the Suspend button."; };
          reboot   = mkOption { type = types.str; default = defaultActions.reboot;   description = "Command executed for the Reboot button."; };
          poweroff = mkOption { type = types.str; default = defaultActions.poweroff; description = "Command executed for the Poweroff button."; };
          logout   = mkOption { type = types.str; default = defaultActions.logout;   description = "Command executed for the Logout button."; };
        };
      };
      description = "Shell commands for each action.";
    };

    # Per-action label glyphs (Nerd Font). Change to words if you prefer text labels.
    icons = mkOption {
      type = types.submodule {
        options = {
          lock     = mkOption { type = types.str; default = defaultIcons.lock;     description = "Label for Lock."; };
          suspend  = mkOption { type = types.str; default = defaultIcons.suspend;  description = "Label for Suspend."; };
          reboot   = mkOption { type = types.str; default = defaultIcons.reboot;   description = "Label for Reboot."; };
          poweroff = mkOption { type = types.str; default = defaultIcons.poweroff; description = "Label for Poweroff."; };
          logout   = mkOption { type = types.str; default = defaultIcons.logout;   description = "Label for Logout."; };
        };
      };
      description = "Per-action labels (icons or text).";
    };

    # Extra CSS appended to the generated style.css
    extraCss = mkOption {
      type = types.lines;
      default = "";
      description = "Additional CSS appended at the end of style.css.";
    };

    # Backdrop alpha as a 2-hex digit string (e.g. 'E6' ~ 90%, 'CC' ~ 80%, '99' ~ 60%).
    cssBackdropAlphaHex = mkOption {
      type = types.str;
      default = "E6";
      example = "CC";
      description = "Two-digit hex alpha applied to the window background color.";
    };
  };

  config = mkIf cfg.enable {
    # Install wlogout and hyprlock (required by your Lock action).
    home.packages = with pkgs; [ wlogout hyprlock ];

    # If the user toggles lockFirstOnSuspend=false, rewrite the suspend action automatically.
    # (Users can still override actions.suspend manually afterwards if they want.)
    willwitcher.wlogout.actions.suspend = lib.mkIf (!cfg.lockFirstOnSuspend) "systemctl suspend";

    # --- wlogout layout (JSON) ---
    xdg.configFile."wlogout/layout".text = layoutJson;

    # --- wlogout CSS (GTK CSS-like) ---
    # Note: CSS uses Base16 values (no '#'), we add the leading '#'.
    xdg.configFile."wlogout/style.css".text = ''
      /* Generated by willwitcher.wlogout module
         - Palette source: ${if cfg.useStylixColors then "Stylix" else "fallback"}
         - Font: ${sansFont}
      */

      window {
        /* Slightly transparent backdrop (base00 with alpha) */
        background-color: #${c.base00}${alphaHex};
      }

      /* Buttons share the same base style; each action gets its own background below */
      button {
        border-radius: 18px;
        border: 2px solid #${c.base03};
        background: #${c.base01};
        color: #${c.base06};
        padding: 18px 22px;
        margin: 10px;
        font-family: "${sansFont}";
        font-size: 18px;
      }

      button:hover {
        background: #${c.base02};
        border-color: #${c.base0D};
        color: #${c.base07};
      }

      /* Per-action colors (tweak freely) */
      #poweroff { background: #${actionBg.poweroff}; }
      #reboot   { background: #${actionBg.reboot};   }
      #suspend  { background: #${actionBg.suspend};  }
      #logout   { background: #${actionBg.logout};   }
      #lock     { background: #${actionBg.lock};     }

      ${cfg.extraCss}
    '';
  };
}

