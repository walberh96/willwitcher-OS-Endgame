{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkForce;
in
{
  options.willwitcher.hyprland.enable =
    mkEnableOption "Enable WillWitcher Hyprland config (Stylix owns colors)";

  config = mkIf config.willwitcher.hyprland.enable {
    # Tools used by binds/autostart
    home.packages = with pkgs; [
      hyprpicker hyprshot mpvpaper brightnessctl playerctl
      networkmanagerapplet blueman swaynotificationcenter waybar udiskie signal-desktop
    ];

    # Let Stylix theme Hyprland, but do NOT enable hyprpaper (you use mpvpaper)
    stylix.targets.hyprland.enable = true;
    stylix.targets.hyprland.hyprpaper.enable = mkForce true;

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
          "waybar" "nm-applet" "blueman-applet" "udiskie" "signal-desktop"
          "steam -silent"
          "hyprpaper"
        ];

        ################################
        ## Look & Feel (no colors here — Stylix controls them)
        ################################
        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
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
            # color -> Stylix
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

        device = [ { name = "epic-mouse-v1"; sensitivity = -0.5; } ];

        ################################
        ## Binds (inline mod/commands — no $vars)
        ################################
        bind = [
          "SUPER, Return, exec, kitty"
          "SUPER, Q, killactive,"
          "SUPER, M, exit,"
          "SUPER, E, exec, thunar"
          "SUPER, V, togglefloating,"
          "SUPER, D, exec, wofi --show drun"
          "SUPER, P, pseudo,"
          "SUPER, J, togglesplit,"

          "SUPER, left, movefocus, l"
          "SUPER, right, movefocus, r"
          "SUPER, up, movefocus, u"
          "SUPER, down, movefocus, d"

          "SUPER, 1, workspace, 1"
          "SUPER, 2, workspace, 2"
          "SUPER, 3, workspace, 3"
          "SUPER, 4, workspace, 4"
          "SUPER, 5, workspace, 5"
          "SUPER, 6, workspace, 6"
          "SUPER, 7, workspace, 7"
          "SUPER, 8, workspace, 8"
          "SUPER, 9, workspace, 9"
          "SUPER, 0, workspace, 10"

          "SUPER SHIFT, 1, movetoworkspace, 1"
          "SUPER SHIFT, 2, movetoworkspace, 2"
          "SUPER SHIFT, 3, movetoworkspace, 3"
          "SUPER SHIFT, 4, movetoworkspace, 4"
          "SUPER SHIFT, 5, movetoworkspace, 5"
          "SUPER SHIFT, 6, movetoworkspace, 6"
          "SUPER SHIFT, 7, movetoworkspace, 7"
          "SUPER SHIFT, 8, movetoworkspace, 8"
          "SUPER SHIFT, 9, movetoworkspace, 9"
          "SUPER SHIFT, 0, movetoworkspace, 10"

          "SUPER, S, togglespecialworkspace, magic"
          "SUPER SHIFT, S, movetoworkspace, special:magic"

          "SUPER, mouse_down, workspace, e+1"
          "SUPER, mouse_up, workspace, e-1"

          ''SUPER SHIFT, P, exec, sh -c 'hyprpicker -a | tr -d "\n" | tee >(wl-copy) >(xargs -I{} notify-send "Color Picked" "{} copied to clipboard")' ''
          ", Print, exec, hyprshot -m region -o ~/Screenshots/ | wl-copy"
          "SUPER SHIFT, L, exec, hyprlock"
        ];

        # held/locked repeats (Hyprland supports combining flags: e.g. bindel)
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
          "SUPER, mouse:272, movewindow"
          "SUPER, mouse:273, resizewindow"
        ];

        windowrule = [
          "suppressevent maximize, class:.*"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        ];
      };

      # No extraConfig: we removed $vars to avoid ordering problems
    };
  };
}
