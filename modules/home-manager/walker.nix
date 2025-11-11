{ config, pkgs, lib, inputs ? {}, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption types;

  # Try to take Elephant & providers from the flake; fallback to pkgs if available.
  elephantPkg =
    (inputs.elephant.packages.${pkgs.system}.default or pkgs.elephant or null);
  providerListPkg =
    (inputs.elephant.packages.${pkgs.system}.providerlist or pkgs.elephant-providerlist or null);
  desktopAppsPkg =
    (inputs.elephant.packages.${pkgs.system}.desktopapplications or pkgs.elephant-desktopapplications or null);

in
{
  ################################################################################
  # OPTION
  ################################################################################
  options.willwitcher.walker = {
    enable = mkEnableOption "Enable Walker as the default launcher (Stylix-owned theming via GTK).";
    addHyprBind = mkOption {
      type = types.bool;
      default = true;
      description = "Bind SUPER+SPACE to Walker in Hyprland.";
    };
  };

  ################################################################################
  # CONFIG
  ################################################################################
  config = mkIf config.willwitcher.walker.enable {

    # Walker via Home-Manager module; runs as a user service.
    programs.walker = {
      enable = true;
      runAsService = true; # Only supported in HM per upstream docs
      # Keep Walker's default theme so Stylix/GTK drive look & feel.
      config = {
        placeholders."default" = { input = "Search..."; list = "Type to search"; };
        # A couple of handy prefixes (opt-in):
        providers.prefixes = [
          { provider = "providerlist"; prefix = "_"; }
          { provider = "websearch";    prefix = "+"; }
        ];
      };
    };

    # Install Elephant and core providers if we can resolve them.
    home.packages = lib.filter (p: p != null) [
      elephantPkg
      providerListPkg
      desktopAppsPkg
    ];

    # Run Elephant as a systemd --user service (Walker needs it running)
    systemd.user.services.elephant = mkIf (elephantPkg != null) {
      Unit = {
        Description = "Elephant data provider backend for Walker";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        # Keep PATH sane so providers are found
        ExecStart = "${lib.getExe elephantPkg}";
        Restart = "on-failure";
        RestartSec = 1;
        Environment = [
          "PATH=${lib.makeBinPath (lib.filter (p: p != null) [ elephantPkg providerListPkg desktopAppsPkg pkgs.coreutils ])}"
        ];
      };
      Install = { WantedBy = [ "default.target" ]; };
    };

  };
}

