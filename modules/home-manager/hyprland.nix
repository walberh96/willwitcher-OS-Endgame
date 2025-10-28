{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkForce;
in
{
  options.willwitcher.hyprland.enable =
    mkEnableOption "Enable WillWitcher Hyprland config (Stylix owns colors)";

  config = mkIf config.willwitcher.hyprland.enable {
    # Apps usadas por binds/autostart
    home.packages = with pkgs; [
      hyprpicker hyprshot mpvpaper brightnessctl playerctl
      networkmanagerapplet blueman swaynotificationcenter waybar udiskie signal-desktop
    ];

    # Deja que Stylix pinte Hyprland (colores/paleta), pero NO hyprpaper
    stylix.targets.hyprland.enable = true;
    stylix.targets.hyprland.hyprpaper.enable = mkForce false;

    wayland.windowManager.hyprland = {
      enable = true;
      # package = pkgs.hyprland;

      settings = {
        ################################
        ## Monitors
        ################################
        monitor = [ ",1920x1080@100,auto,auto" ];

        ################################
        ## Workspaces (persistent)
        ################################
        workspace = [
          "1,persistent:true" "2,persistent:true" "3,persistent:true"
          "4,persistent:true" "5,persistent:true"
        ];

        ################################
        ## Autostart (exec-once)
        ################################
        exec-once = [
          #''mpvpaper -o "no-audio --loop" DP-3 ~/Wallpapers/ww-os-green.mp4''
          "waybar" "swaync" "nm-applet" "blueman-applet" "udiskie" "signal-desktop"
          "steam -silent"
        ];

        ################################
        ## Look & Feel (sin colores: Stylix los maneja)
        ################################
        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
          # NO: col.active_border / col.inactive_border (Stylix)
        };

        decoration = {
          rounding = 10;
          rounding_power = 2;
          active_opacity = 1.0;
          inactive_opacity = 1.0;
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            # NO: color (Stylix)
          };
          blur = { enabled = true; size = 3; passes = 1; vibrancy = 0.1696; };
        };

        animations = {
          enabled = true;
          bezier = [
            "easeOutQuint,0.23,1,0.32,1"
            "easeInOutCubic,0.65,0.05,0.36,1"
            "linear,0,0,1,1"
            "almostLinear,0.5,0.5,0.75,1.0"
            "quick,0.15,0,0.1,1"
          ];
          animation = [
            "global, 1, 10, default"
            "border, 1, 5.39, easeOutQuint"
            "windows, 1, 4.79, easeOutQuint"
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
            "windowsOut, 1, 1.49, linear, popin 87%"
            "fadeIn, 1, 1.73, almostLinear"
            "fadeOut, 1, 1.46, almostLinear"
            "fade, 1, 3.03, quick"
            "layers, 1, 3.81, easeOutQuint"
            "layersIn, 1, 4, easeOutQuint, fade"
            "layersOut, 1, 1.5, linear, fade"
            "fadeLayersIn, 1, 1.79, almostLinear"
            "fadeLayersOut, 1, 1.39, almostLinear"
            "workspaces, 1, 1.94, almostLinear, fade"
            "workspacesIn, 1, 1.21, almostLinear, fade"
            "workspacesOut, 1, 1.94, almostLinear, fade"
          ];
        };

        dwindle = { pseudotile = true; preserve_split = true; };
        master  = { new_status = "master"; };
        misc    = { force_default_wallpaper = 0; disable_hyprland_logo = true; };

        ################################
        ## Input / gestures / per-device
        ################################
        input = {
          kb_layout = "us";
          kb_variant = ""; kb_model = ""; kb_options = ""; kb_rules = "";
          follow_mouse = 1;
          sensitivity = 0;
          touchpad.natural_scroll = false;
        };

        gestures.workspace_swipe = false;

        device = [ { name = "epic-mouse-v1"; sensitivity = -0.5; } ];

        ################################
        ## Binds
        ################################
        bind = [
          "$mainMod, Return, exec, $terminal"
          "$mainMod, Q, killactive," "$mainMod, M, exit," "$mainMod, E, exec, $fileManager"
          "$mainMod, V, togglefloating," "$mainMod, D, exec, $menu"
          "$mainMod, P, pseudo," "$mainMod, J, togglesplit,"

          "$mainMod, left, movefocus, l" "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"   "$mainMod, down, movefocus, d"

          "$mainMod, 1, workspace, 1" "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3" "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5" "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7" "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9" "$mainMod, 0, workspace, 10"

          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"

          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"

          ''SUPER SHIFT, P, exec, sh -c 'hyprpicker -a | tr -d "\n" | tee >(wl-copy) >(xargs -I{} notify-send "Color Picked" "{} copied to clipboard")' ''
          ", Print, exec, hyprshot -m region -o ~/Screenshots/ | wl-copy"
          "SUPER SHIFT, L, exec, hyprlock"
        ];

        bindel = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute,     exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ", XF86MonBrightnessUp,   exec, brightnessctl -e4 -n2 set 5%+"
          ", XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
        ];

        bindl = [
          ", XF86AudioNext,  exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay,  exec, playerctl play-pause"
          ", XF86AudioPrev,  exec, playerctl previous"
        ];

        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        windowrule = [
          "suppressevent maximize, class:.*"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        ];
      };

      # Variables/macros
      extraConfig = ''
        $terminal = kitty
        $fileManager = thunar
        $menu = wofi --show drun
        $mainMod = SUPER
      '';
    };
  };
}
