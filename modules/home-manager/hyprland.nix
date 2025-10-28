{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;
in
{
  ################################################################################
  # WillWitcherOS Hyprland module (Home Manager)
  # - Declarative Hyprland configuration via HM's native module
  # - Encodes your previous hyprland.conf, but as options
  # - Keeps Home Manager tidy by isolating Hyprland in a module
  ################################################################################

  options.ww.hyprland.enable = mkEnableOption "Enable WillWitcher Hyprland config";

  config = mkIf config.ww.hyprland.enable {

    # Ensure required user-level tools are present
    home.packages = with pkgs; [
      # helpers used in your binds/autostarts
      hyprpicker
      hyprshot
      mpvpaper
      brightnessctl
      playerctl

      # applets / bar / daemons you autostart
      networkmanagerapplet
      blueman
      swaynotificationcenter
      waybar
      udiskie
      signal-desktop
    ];

    # Hyprland managed via Home Manager
    wayland.windowManager.hyprland = {
      enable = true;
      # package = pkgs.hyprland;  # uncomment if you want HM to pick the package

      ##########################################################################
      ## HM "settings" mirrors Hyprland keywords in a structured way.
      ## Strings that look like "keyword = value" become entries in hyprland.conf
      ##########################################################################
      settings = {
        ################################
        ## Monitors
        ################################
        # Your previous line: monitor=,1920x1080@100,auto,auto
        monitor = [ ",1920x1080@100,auto,auto" ];

        ################################
        ## Workspaces (persistent)
        ################################
        workspace = [
          "1,persistent:true"
          "2,persistent:true"
          "3,persistent:true"
          "4,persistent:true"
          "5,persistent:true"
        ];

        ################################
        ## Autostart (exec-once)
        ################################
        exec-once = [
          # video wallpaper on output DP-3 (keep if you actually have DP-3)
          #''mpvpaper -o "no-audio --loop" DP-3 ~/Wallpapers/ww-os-green.mp4''
          "waybar"
          "swaync"
          "nm-applet"
          "blueman-applet"
          "udiskie"
          "signal-desktop"
          "steam -silent"
        ];

        ################################
        ## Look & Feel: general / decoration / animations
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
            color = "rgba(1a1a1aee)";
          };

          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
        };

        animations = {
          # "yes, please :)" works too, but let's use `true` for clarity
          enabled = true;

          # Each line corresponds to "bezier = name,x1,y1,x2,y2"
          bezier = [
            "easeOutQuint,0.23,1,0.32,1"
            "easeInOutCubic,0.65,0.05,0.36,1"
            "linear,0,0,1,1"
            "almostLinear,0.5,0.5,0.75,1.0"
            "quick,0.15,0,0.1,1"
          ];

          # "animation = target, enabled, speed, curve[,style %]"
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

        ################################
        ## Layouts
        ################################
        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        master = {
          new_status = "master";
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };

        ################################
        ## Input / gestures / per-device
        ################################
        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "";
          kb_rules = "";
          follow_mouse = 1;
          sensitivity = 0; # -1.0..1.0 (0 = no change)

          touchpad = {
            natural_scroll = false;
          };
        };

        gestures = {
          workspace_swipe = false;
        };

        # Per-device config: matches your example block
        device = [
          {
            name = "epic-mouse-v1";
            sensitivity = -0.5;
          }
        ];

        ################################
        ## Binds
        ################################
        # regular binds
        bind = [
          # Window / apps
          "$mainMod, Return, exec, $terminal"
          "$mainMod, Q, killactive,"
          "$mainMod, M, exit,"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, V, togglefloating,"
          "$mainMod, D, exec, $menu"
          "$mainMod, P, pseudo,"
          "$mainMod, J, togglesplit,"

          # Move focus with arrows
          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"

          # Switch workspaces
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"

          # Special "scratchpad" workspace
          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"

          # Scroll through workspaces
          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"

          # Color picker
          ''SUPER SHIFT, P, exec, sh -c 'hyprpicker -a | tr -d "\n" | tee >(wl-copy) >(xargs -I{} notify-send "Color Picked" "{} copied to clipboard")' ''

          # Screenshot to ~/Screenshots + copy path to clipboard
          # (hyprshot prints the saved file path; wl-copy copies it)
          ", Print, exec, hyprshot -m region -o ~/Screenshots/ | wl-copy"

          # Lock
          "SUPER SHIFT, L, exec, hyprlock"
        ];

        # Hold-to-repeat and/or locked binds
        bindel = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute,     exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ", XF86MonBrightnessUp,   exec, brightnessctl -e4 -n2 set 5%+"
          ", XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
        ];

        bindl = [
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
        ];

        # Mouse bindings
        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        ################################
        ## Window / workspace rules
        ################################
        windowrule = [
          "suppressevent maximize, class:.*"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        ];
      };

      ##########################################################################
      ## Extra config for Hyprland-specific variables/macros.
      ## HM doesn't have explicit options for "$vars", so we declare them here.
      ##########################################################################
      extraConfig = ''
        $terminal = kitty
        $fileManager = thunar
        $menu = wofi --show drun
        $mainMod = SUPER
      '';
    };

    ##########################################################################
    ## NOTE on wallpapers vs Stylix hyprpaper:
    ## You autostart `mpvpaper` (video wallpaper). To avoid conflicts,
    ## keep Stylix's hyprpaper target disabled (or don't enable it).
    ##########################################################################
  };
}
