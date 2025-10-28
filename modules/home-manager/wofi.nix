{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.willwitcher.wofi.enable =
    mkEnableOption "Enable WillWitcher Wofi config (Stylix owns palette)";

  config = mkIf config.willwitcher.wofi.enable {
    # Let Stylix theme Wofi (colors/fonts). We don't set any CSS here.
    stylix.targets.wofi.enable = true;

    programs.wofi = {
      enable = true;
      package = pkgs.wofi;

      # Do NOT set `style` so Stylix controls styling.
      # style = '''';  # (leave unset intentionally)

      # Plain Wofi config (key=value). No colors here.
      settings = {
        insensitive     = true;
        width           = 500;
        height          = 300;
        prompt          = "Search...";
        allow_images    = true;
        image_size      = 24;
        dynamic_lines   = true;
        allow_markup    = true;
        no_actions      = true;
      };
    };
  };
}
