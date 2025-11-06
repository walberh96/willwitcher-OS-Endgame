{ lib, pkgs, config, options, ... }:

let
  cfg = config.willwitcher.vesktop;

  # Does Home Manager expose the `programs.vesktop` module?
  hasHMVesktop =
    lib.hasAttrByPath [ "programs" "vesktop" "enable" ] options;

  # Is Stylix imported and does it declare the `stylix.targets.vesktop` option?
  hasStylixTarget =
    lib.hasAttrByPath [ "stylix" "targets" "vesktop" "enable" ] options;

in
{
  ################################################################################
  # OPTIONS
  ################################################################################
  options.willwitcher.vesktop = with lib; {
    enable = mkEnableOption "Vesktop + Vencord declarativos";

    stylixTarget = mkOption {
      type = types.bool;
      default = true;
      description = "Habilita stylix.targets.vesktop si Stylix está presente.";
    };

    useSystemVencord = mkOption {
      type = types.bool;
      default = true;
      description = "Usar Vencord del sistema (desactiva el autoupdater interno).";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.vesktop;
      description = "Paquete de Vesktop a instalar.";
    };

    settings = mkOption {
      type = types.attrs;
      default = {
        tray = true;
        minimizeToTray = true;
        hardwareAcceleration = true;
        discordBranch = "stable";
      };
      description = "Opciones para programs.vesktop.settings.";
    };
  };

  ################################################################################
  # CONFIG
  # Implementation uses mkMerge with existence checks (no side-effects on `options`)
  ################################################################################
  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Path A: If HM exposes the Vesktop module, use it.
    (lib.mkIf hasHMVesktop {
      programs.vesktop = {
        enable = true;
        package = cfg.package;
        settings = cfg.settings;
        vencord.useSystem = cfg.useSystemVencord;
      };
    })

    # Path B (fallback): If the module is not available, ensure the package is installed.
    (lib.mkIf (!hasHMVesktop) {
      home.packages = [ cfg.package ];
    })

    # Stylix target: enable only if Stylix option exists and the toggle is on.
    (lib.mkIf (cfg.stylixTarget && hasStylixTarget) {
      stylix.targets.vesktop.enable = true;
    })
  ]);
}

