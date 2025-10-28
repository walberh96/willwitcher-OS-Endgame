{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.willwitcher.swaync.enable =
    mkEnableOption "Enable WillWitcher Sway Notification Center (Stylix/GTK handles colors)";

  config = mkIf config.willwitcher.swaync.enable {
    # TIP: ensure Stylix GTK target is on so SwayNC inherits the palette
    stylix.targets.gtk.enable = true;

    # Enable Sway Notification Center as a user service.
    services.swaync = {
      enable = true;
      package = pkgs.swaynotificationcenter;

      # We intentionally DO NOT set `style` or `settings`:
      # - no CSS here -> Stylix/GTK decides look & feel
      # - SwayNC falls back to its default config.json
      # style = '''';      # leave unset
      # settings = { };    # leave unset
    };

    # Optional: if you previously autostarted `swaync` from Hyprland,
    # remove it to avoid double instances. (See snippet below.)
  };
}
