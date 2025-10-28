{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.willwitcher.btop.enable =
    mkEnableOption "Enable WillWitcher btop config (palette comes from terminal / Stylix)";

  config = mkIf config.willwitcher.btop.enable {
    programs.btop = {
      enable = true;

      # We keep colors out; use the built-in "TTY" theme so btop follows Kitty's palette (which Stylix themes).
      settings = {
        # --- Visuals (no hardcoded colors) ---
        color_theme = "TTY";        # Uses terminal 16-color palette
        truecolor = true;           # 24-bit color support if theme uses it (TTY sticks to 16)
        theme_background = false;   # Show terminal background instead of theme bg when possible
        rounded_corners = true;     # Aesthetics

        # --- UX ---
        vim_keys = true;            # Familiar keybinds
        update_ms = 1000;           # Refresh rate (ms)
        shown_boxes = "proc cpu mem net";  # Default visible boxes
        proc_sorting = "cpu lazy";  # Practical default
        proc_tree = true;           # Tree view for processes
        show_cpu_freq = true;
        show_coretemp = true;
        temp_scale = "celsius";     # or "fahrenheit"
        graph_symbol = "braille";   # Smooth graphs (fallbacks to block if unsupported)

        # --- Misc ---
        # If you dislike mouse, you can turn it off:
        # mouse_support = false;
      };
    };

    # Tip: if btop was previously in `home.packages`, you can remove it now since HM installs it.
  };
}
