{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.willwitcher.zed.enable =
    mkEnableOption "Enable WillWitcher Zed editor (minimal settings; theme follows system)";

  config = mkIf config.willwitcher.zed.enable {
    # Install Zed at the user level
    home.packages = [ pkgs.zed-editor ];

    # Zed config directory: ~/.config/zed/
    # We write a conservative starter settings.json.
    # - No hardcoded colors so it follows your system/dark theme
    # - Safe editor ergonomics (tabs -> spaces, format on save, soft wrap at 100)
    xdg.configFile."zed/settings.json".text = builtins.toJSON {
      # Follow the system theme (Dark/Light). You can also set "Dark" or "Light".
      theme = "System";

      # UI & editor font sizes (Zed ignores unknown keys harmlessly)
      ui_font_size = 12;
      buffer_font_size = 12;

      # Editor behavior
      soft_wrap = "preferred_line_length";  # wrap long lines
      preferred_line_length = 100;
      tab_size = 4;
      translate_tabs_to_spaces = true;
      format_on_save = true;

      # Show small inline git diffs (if Zed supports it; otherwise ignored)
      show_inline_git_diff = true;

      # Save automatically when switching focus (safe default)
      auto_save = "on_focus_change";
    };

    # If you later want custom keybindings or snippets, we can add:
    # xdg.configFile."zed/keymap.json".text = builtins.toJSON [ ... ];
    # xdg.configFile."zed/snippets.json".text = builtins.toJSON { ... };
  };
}
