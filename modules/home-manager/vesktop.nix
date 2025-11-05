# modules/home-manager/vesktop.nix
{ lib, pkgs, config, ... }:

let
  cfg = config.willwitcher.vesktop;
in
{
  options.willwitcher.vesktop = with lib; {
    enable = mkEnableOption "Vesktop + Vencord configurados declarativamente";

    # Si usas Stylix, esto enciende su target para Vesktop.
    stylixTarget = mkOption {
      type = types.bool;
      default = true;
      description = "Habilita stylix.targets.vesktop si Stylix está presente.";
    };

    # Usa el Vencord del sistema (recomendado).
    useSystemVencord = mkOption {
      type = types.bool;
      default = true;
      description = "Usar Vencord empaquetado por nix en lugar del autoupdater.";
    };

    # Paquete (por si quieres sobreescribirlo).
    package = mkOption {
      type = types.package;
      default = pkgs.vesktop;
      description = "Paquete de Vesktop a instalar.";
    };

    # Ajustes típicos de Vesktop (puedes extenderlos).
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

  config = lib.mkIf cfg.enable (
    {
      programs.vesktop = {
        enable = true;
        package = cfg.package;
        settings = cfg.settings;
        vencord.useSystem = cfg.useSystemVencord;
      };
    }
    # Solo intentamos tocar Stylix si realmente está importado en tu sistema,
    # así evitamos errores de “opción no definida”.
    // lib.optionalAttrs (lib.hasAttrByPath [ "stylix" ] config) {
      stylix.targets.vesktop.enable = cfg.stylixTarget;
    }
  );
}
