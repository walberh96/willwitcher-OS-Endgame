# modules/home-manager/wlogout.nix
{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption mkIf mkOption types attrByPath mkMerge concatStringsSep toLower;

  cfg = config.willwitcher.wlogout;

  # --- Stylix palette (fallback if Stylix not present) ---
  defaultPalette = {
    base00 = "1e1e2e"; base01 = "181825"; base02 = "313244"; base03 = "45475a";
    base04 = "585b70"; base05 = "cdd6f4"; base06 = "f5e0dc"; base07 = "b4befe";
    base08 = "f38ba8"; base09 = "fab387"; base0A = "f9e2af"; base0B = "a6e3a1";
    base0C = "94e2d5"; base0D = "89b4fa"; base0E = "cba6f7"; base0F = "f2cdcd";
  };
  c = attrByPath [ "lib" "stylix" "colors" ] defaultPalette config;
  sansFont = attrByPath [ "stylix" "fonts" "sansSerif" "name" ] "Inter" config;

  # --- Actions / Icons / Labels ---
  defaultActions = {
    lock     = "hyprlock";
    suspend  = "hyprlock & sleep 0.4 && systemctl suspend";
    reboot   = "systemctl reboot";
    poweroff = "systemctl poweroff";
    logout   = "hyprctl dispatch exit 0";
    desktop  = "${pkgs.procps}/bin/pkill -x wlogout"; # “volver al desktop”
  };
  defaultIcons = {
    lock     = "";  # Nerd Font
    suspend  = "";
    reboot   = "";
    poweroff = "";
    logout   = "";
    desktop  = "";
  };
  defaultLabels = {
    lock     = "Lock";
    suspend  = "Suspend";
    reboot   = "Reboot";
    poweroff = "Poweroff";
    logout   = "Logout";
    desktop  = "Desktop";
  };

  # Colores por acción (se aplican al TEXTO: label + icon)
  actionFg = {
    poweroff = c.base08; # red
    reboot   = c.base0A; # yellow
    suspend  = c.base0B; # green
    logout   = c.base0C; # teal
    lock     = c.base0D; # blue
    desktop  = c.base06; # neutral/text
  };

  cfgHome = config.xdg.configHome;  # usually ~/.config

  # Wrapper: fuerza columnas y usa *tu* layout/CSS (evita layouts del sistema)
  menu = pkgs.writeShellScriptBin "wlogout-menu" ''
    exec ${pkgs.wlogout}/bin/wlogout \
      -p layer-shell \
      -b ${toString cfg.columns} \
      -l "${cfgHome}/wlogout/layout" \
      -C "${cfgHome}/wlogout/style.css"
  '';

  # --- rgba() helpers to avoid GTK opacity flicker ---
  hexMap = {
    "0"=0;"1"=1;"2"=2;"3"=3;"4"=4;"5"=5;"6"=6;"7"=7;"8"=8;"9"=9;
    "a"=10;"b"=11;"c"=12;"d"=13;"e"=14;"f"=15;
  };
  hex2 = s:
    16 * (hexMap.${toLower (builtins.substring 0 1 s)}) +
          hexMap.${toLower (builtins.substring 1 1 s)};
  hexToRGB = hex: {
    r = hex2 (builtins.substring 0 2 hex);
    g = hex2 (builtins.substring 2 2 hex);
    b = hex2 (builtins.substring 4 2 hex);
  };
  base00Rgb = hexToRGB c.base00;

  # Helper: un objeto JSON por línea para layout
  mkBtn = name: text: action: key:
    builtins.toJSON { label = name; action = action; text = text; keybind = key; };

  # TEXTO = "Label Icon" (sin saltos de línea)
  layoutText =
    concatStringsSep "\n" [
      (mkBtn "lock"     (defaultLabels.lock     + " " + defaultIcons.lock)     cfg.actions.lock     "l")
      (mkBtn "suspend"  (defaultLabels.suspend  + " " + defaultIcons.suspend)  cfg.actions.suspend  "s")
      (mkBtn "reboot"   (defaultLabels.reboot   + " " + defaultIcons.reboot)   cfg.actions.reboot   "r")
      (mkBtn "poweroff" (defaultLabels.poweroff + " " + defaultIcons.poweroff) cfg.actions.poweroff "p")
      (mkBtn "logout"   (defaultLabels.logout   + " " + defaultIcons.logout)   cfg.actions.logout   "e")
      (mkBtn "desktop"  (defaultLabels.desktop  + " " + defaultIcons.desktop)  cfg.actions.desktop  "d")
    ];
in
{
  options.willwitcher.wlogout = {
    enable = mkEnableOption "Styled wlogout menu (Stylix colors, hyprlock lock).";

    # 6 botones → 6 por fila por defecto
    columns = mkOption {
      type = types.int; default = 6;
      description = "Buttons per row; used by the wrapper (wlogout -b <n>).";
    };

    # Alpha 0..1 para rgba() (sin flicker)
    backdropAlpha = mkOption {
      type = types.number; default = 0.92;
      description = "Alpha (0..1) for window background using rgba().";
    };

    # Si no quieres lock antes de suspender, desactívalo
    lockFirstOnSuspend = mkOption {
      type = types.bool; default = true;
      description = "Run hyprlock, wait briefly, then suspend.";
    };

    # Permite override de acciones/íconos/labels si quisieras
    actions = mkOption {
      default = {};
      type = types.submodule {
        options = {
          lock     = mkOption { type = types.str; default = defaultActions.lock;     };
          suspend  = mkOption { type = types.str; default = defaultActions.suspend;  };
          reboot   = mkOption { type = types.str; default = defaultActions.reboot;   };
          poweroff = mkOption { type = types.str; default = defaultActions.poweroff; };
          logout   = mkOption { type = types.str; default = defaultActions.logout;   };
          desktop  = mkOption { type = types.str; default = defaultActions.desktop;  };
        };
      };
      description = "Shell commands for each action.";
    };

    icons = mkOption {
      default = {};
      type = types.submodule {
        options = {
          lock     = mkOption { type = types.str; default = defaultIcons.lock;     };
          suspend  = mkOption { type = types.str; default = defaultIcons.suspend;  };
          reboot   = mkOption { type = types.str; default = defaultIcons.reboot;   };
          poweroff = mkOption { type = types.str; default = defaultIcons.poweroff; };
          logout   = mkOption { type = types.str; default = defaultIcons.logout;   };
          desktop  = mkOption { type = types.str; default = defaultIcons.desktop;  };
        };
      };
      description = "Nerd Font glyphs used inside the button text.";
    };

    labels = mkOption {
      default = {};
      type = types.submodule {
        options = {
          lock     = mkOption { type = types.str; default = defaultLabels.lock;     };
          suspend  = mkOption { type = types.str; default = defaultLabels.suspend;  };
          reboot   = mkOption { type = types.str; default = defaultLabels.reboot;   };
          poweroff = mkOption { type = types.str; default = defaultLabels.poweroff; };
          logout   = mkOption { type = types.str; default = defaultLabels.logout;   };
          desktop  = mkOption { type = types.str; default = defaultLabels.desktop;  };
        };
      };
      description = "Plain text labels shown before the icon.";
    };

    extraCss = mkOption { type = types.lines; default = ""; };
    textFontSizePx = mkOption {
      type = types.int; default = 28;  # tamaño combinado label+icon
      description = "Font size (px) for the button text (label + icon).";
    };
    minButtonHeightPx = mkOption {
      type = types.int; default = 120;
      description = "Ensures the text has enough space.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = with pkgs; [ wlogout hyprlock procps menu ];

      # --- Layout: 6 botones (un objeto JSON por línea) ---
      xdg.configFile."wlogout/layout".text = layoutText;

      # --- CSS: fondo único, texto por acción, sin rounded corners, rgba sin flicker ---
      xdg.configFile."wlogout/style.css".text = ''
        /* Generated by willwitcher.wlogout
           - Palette: Stylix/fallback
           - Single background color for all buttons (base01)
           - Per-action colors applied to TEXT (label + icon)
           - RGBA background for the window (no global opacity)
        */

        window {
          background-color: rgba(${toString base00Rgb.r}, ${toString base00Rgb.g}, ${toString base00Rgb.b}, ${toString cfg.backdropAlpha});
        }

        button {
          border-radius: 0;                      /* no rounded corners */
          border: 2px solid #${c.base03};
          background: #${c.base01};              /* same for all buttons */
          color: #${c.base06};                   /* default text color (overridden per action below) */
          margin: 10px;
          min-height: ${toString cfg.minButtonHeightPx}px;
          padding: 24px 28px;

          /* Nerd Font first for icons; Inter as fallback */
          font-family: "Symbols Nerd Font", "Symbols Nerd Font Mono", "Noto Sans Symbols 2", "${sansFont}", "DejaVu Sans";
          font-size: ${toString cfg.textFontSizePx}px;
        }

        button:hover {
          background: #${c.base02};              /* keep text color on hover */
          border-color: #${c.base0D};
        }

        /* Per-action TEXT colors (label + icon) */
        #poweroff { color: #${actionFg.poweroff}; }
        #reboot   { color: #${actionFg.reboot};   }
        #suspend  { color: #${actionFg.suspend};  }
        #logout   { color: #${actionFg.logout};   }
        #lock     { color: #${actionFg.lock};     }
        #desktop  { color: #${actionFg.desktop};  }

        ${cfg.extraCss}
      '';
    }

    (mkIf (!cfg.lockFirstOnSuspend) {
      willwitcher.wlogout.actions.suspend = "systemctl suspend";
    })
  ]);
}

