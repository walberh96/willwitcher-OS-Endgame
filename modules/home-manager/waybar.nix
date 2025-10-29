{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkForce;
  # Paleta de Stylix con '#'
  c = config.lib.stylix.colors.withHashtag;
in
{
  options.willwitcher.waybar.enable =
    mkEnableOption "Enable WillWitcher Waybar config (Stylix owns palette)";

  config = mkIf config.willwitcher.waybar.enable {

    # Stylix sí, pero sin inyectar su CSS completo (evita choques)
    stylix.targets.waybar = {
      enable = true;
      addCss = false;  # dejamos el CSS 100% a nuestro cargo
    };

    programs.waybar = {
      enable = true;

      # Nuestro CSS, usando la paleta de Stylix (sin hardcodear)
      style = mkForce ''
        /* Estructura: Stylix pinta colores y fuentes */
        * {
          /* no seteamos font-family: lo pone Stylix */
          font-size: 16px; /* opcional; quítalo si quieres 100% Stylix */
        }

        window#waybar {
          background-color: transparent;
        }

        #workspaces {
          background: ${c.base00};
          color: ${c.base05};
          border-radius: 15px;
          margin-top: 10px;
          margin-right: 10px;
          margin-left: 5px;
          padding: 4px;
          border: 1px solid ${c.base02};
        }

        #workspaces button {
          background: transparent;
          color: ${c.base0E};
          border-radius: 10px;
          margin: 0 3px;
          padding: 4px 10px;
          font-weight: 600;
          box-shadow: none;
        }

        #workspaces button.active {
          background-color: ${c.base01};
          color: ${c.base0D};
        }

        #workspaces button:not(.active):not(.empty) {
          background-color: ${c.base00};
          color: ${c.base0B};
        }

        /* Bloques tipo “píldora” a la derecha/centro */
        #clock,
        #tray,
        #custom-notification,
        #pulseaudio,
        #custom-power {
          background: ${c.base00};
          color: ${c.base0E};
          border: 1px solid ${c.base02};
          border-radius: 15px;
          margin-right: 10px;
          margin-top: 10px;
          padding: 4px 16px;
          font-weight: 700;
        }

        #clock {
          font-size: 20px; /* opcional */
          padding-top: 4px;
          padding-bottom: 2px;
        }

        #custom-power:hover {
          color: ${c.base08};
        }
      '';

      # Tus settings intactos
      settings = [
        {
          layer = "top";
          output = "DP-3";
          position = "top";
          height = 50;
          spacing = 5;
          "margin-bottom" = -5;

          "modules-left"   = [ "hyprland/workspaces" ];
          "modules-center" = [ "clock" ];
          "modules-right"  = [ "custom/notification" "pulseaudio" "tray" ];

          "clock" = {
            "format-alt" = "{:%Y-%m-%d}";
            tooltip = false;
          };

          "tray" = {
            "icon-size" = 20;
            spacing = 13;
          };

          "custom/notification" = {
            tooltip = false;
            format = " {icon} ";
            "format-icons" = {
              notification             = ''<span foreground="red"><sup></sup></span>'';
              none                     = "";
              "dnd-notification"       = ''<span foreground="red"><sup></sup></span>'';
              "dnd-none"               = "";
              "inhibited-notification" = ''<span foreground="red"><sup></sup></span>'';
              "inhibited-none"         = "";
              "dnd-inhibited-notification" = ''<span foreground="red"><sup></sup></span>'';
              "dnd-inhibited-none"         = "";
            };
            "return-type" = "json";
            "exec-if" = "which swaync-client";
            exec = "swaync-client -swb";
            "on-click" = "swaync-client -t -sw";
            "on-click-right" = "swaync-client -d -sw";
            escape = true;
          };

          "pulseaudio" = {
            format = "{volume}% {icon}";
            "format-icons" = { default = [ "" "" "" ]; };
            "on-click" = "pwvucontrol";
          };
        }
      ];
    };
  };
}
