{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.willwitcher.zed.enable =
    mkEnableOption "Enable WillWitcher Zed editor (minimal settings; theme follows system)";

  config = mkIf config.willwitcher.zed.enable {
    # Install Zed for the user
    home.packages = [ pkgs.zed-editor ];

    # ~/.config/zed/settings.json (claves no deprecadas)
    xdg.configFile."zed/settings.json".text = lib.generators.toJSON {} {
      theme = "System";                 # follow system theme
      ui_font_size = 16;
      buffer_font_size = 16;

      autosave = "on_focus_change";     # (antes era auto_save)
      format_on_save = "on";            # "on" | "off"

      preferred_line_length = 100;
      soft_wrap = "preferred_line_length";

      tab_size = 12;
      hard_tabs = false;                # use spaces instead of hard tabs
    };

    # Si luego quieres keymap/snippets:
    # xdg.configFile."zed/keymap.json".text = lib.generators.toJSON {} [ ... ];
    # xdg.configFile."zed/snippets.json".text = lib.generators.toJSON {} { ... };
  };
}
