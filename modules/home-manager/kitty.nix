{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkForce;
in
{
  options.willwitcher.kitty.enable =
    mkEnableOption "Enable WillWitcher Kitty config (Stylix owns colors/fonts)";

  config = mkIf config.willwitcher.kitty.enable {
    # Let Stylix theme Kitty (colors & fonts). Do not set kitty colors/fonts here.
    stylix.targets.kitty.enable = true;

    programs.kitty = {
      enable = true;
      package = pkgs.kitty;
      font.size = 16;

      # Shell integration improves things like Ctrl+click on paths, etc.
      shellIntegration.enableZshIntegration = true;

      # Keep settings neutral (no color or font options here).
      settings = {
        # UI/behavior (safe non-color options)
        confirm_os_window_close = 0;   # don't prompt when closing window with multiple tabs
        enable_audio_bell       = "no";
        scrollback_lines        = 10000;
        window_padding_width    = 8;
        cursor_blink_interval   = 0;   # 0 = no blinking
        allow_remote_control    = "yes"; # enables 'kitty @' remote control
        tab_bar_edge            = "top";
        tab_bar_style           = "powerline";
        remember_window_size    = "yes";
        strip_trailing_spaces   = "smart";
        background_opacity = "0.85";
      };

      # Handy keybindings (do not conflict with your Hyprland binds)
      keybindings = {
        "ctrl+shift+c" = "copy_to_clipboard";
        "ctrl+shift+v" = "paste_from_clipboard";
        "ctrl+shift+t" = "new_tab";
        "ctrl+shift+n" = "new_window";
        "ctrl+shift+w" = "close_window";
        "ctrl+shift+enter" = "new_window";
        # Zoom
        "ctrl+plus"  = "increase_font_size";
        "ctrl+minus" = "decrease_font_size";
        "ctrl+0"     = "reset_font_size";
      };
    };
  };
}
