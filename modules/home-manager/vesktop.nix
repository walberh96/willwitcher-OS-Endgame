# modules/home-manager/vesktop.nix
{ lib, pkgs, config, options, ... }:

let
  cfg = config.willwitcher.vesktop;

  # ¿Home Manager trae el módulo programs.vesktop?
  hasHMVesktop =
    lib.hasAttrByPath [ "programs" "vesktop" "enable" ] options;

  # ¿Stylix está importado y declara el target vesktop?
  hasStylixTarget =
    lib.hasAttrByPath [ "stylix" "targets" "vesktop" "enable" ] options;

in {
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

  # Implementación, sin tocar `config` para checks de existencia
  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Ruta A: si existe el módulo de HM para Vesktop, úsalo
    (lib.mkIf hasHMVesktop {
      programs.vesktop = {
        enable = true;
        package = cfg.package;
        settings = cfg.settings;
        vencord.useSystem = cfg.useSystemVencord;
      };
    })

    # Ruta B (fallback): si NO existe el módulo, al menos instala el paquete
    (lib.mkIf (!hasHMVesktop) {
      home.packages = [ cfg.package ];
    })

    # Stylix target, solo si Stylix declara esa opción y el toggle está en true
    (lib.mkIf (cfg.stylixTarget && hasStylixTarget) {
      stylix.targets.vesktop.enable = true;
    })
  ]);
}
