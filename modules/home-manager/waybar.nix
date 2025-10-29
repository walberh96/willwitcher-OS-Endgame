{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkForce;
in
{
  options.willwitcher.waybar.enable =
    mkEnableOption "Enable WillWitcher Waybar config (Stylix owns palette)";

  config = mkIf config.willwitcher.waybar.enable {

    # Deja a Stylix aplicar colores/fuentes en Waybar
    stylix.targets.waybar.enable = true;

    programs.waybar = {
      enable = true;

      # Sin style.css para no chocar con Stylix
      # style = '''';

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
            # "scroll-step" = 1;
            format = "{volume}% {icon}";
            "format-icons" = {
              default = [ "" "" "" ];
            };
            "on-click" = "pwvucontrol";
          };
        }
      ];
    };
  };
}
