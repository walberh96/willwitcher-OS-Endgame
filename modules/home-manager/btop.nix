{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.willwitcher.btop.enable =
    mkEnableOption "Enable WillWitcher btop config (palette from Stylix)";

  config = mkIf config.willwitcher.btop.enable {
    # Let Stylix own btop’s theme/colors
    stylix.targets.btop.enable = true;

    programs.btop = {
      enable = true;
      settings = {
        # No color_theme here → Stylix sets it to "stylix"
        truecolor = true;
        theme_background = false;
        rounded_corners = true;

        # UX
        vim_keys = true;
        update_ms = 1000;
        shown_boxes = "proc cpu mem net";
        proc_sorting = "cpu lazy";
        proc_tree = true;
        show_cpu_freq = true;
        show_coretemp = true;
        temp_scale = "celsius";
        graph_symbol = "braille";
        # mouse_support = false;  # uncomment if you prefer keyboard-only
      };
    };
  };
}
