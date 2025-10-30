{ config, lib, pkgs, ... }:

# Discord / Vesktop (Home Manager) — WillWitcherOS style
#
# What this module does:
# - Instala Discord (o Vesktop) vía Home Manager.
# - Opción para usar Wayland (Electron Ozone) sin pelear con tu tema.
# - (Opcional) Crea un launcher propio “Discord (WillWitcherOS)” con wrapper.
# - (Opcional) Registra el handler x-scheme-handler/discord.
# - (Opcional) Autostart con systemd --user.
#
# How to enable in your home.nix:
#   imports = [ (inputs.self + /modules/home-manager/discord.nix) ];
#   willwitcher.discord.enable = true;
#
# Optional knobs:
#   willwitcher.discord.flavor = "discord" | "ptb" | "canary" | "vesktop";
#   willwitcher.discord.package = pkgs.vesktop;  # override manual del paquete
#   willwitcher.discord.wayland = true;          # NIXOS_OZONE_WL + Electron hint
#   willwitcher.discord.setDefaultURLHandler = true;  # x-scheme-handler/discord
#   willwitcher.discord.autostart = false;       # systemd --user
#   willwitcher.discord.createLauncher = true;   # launcher propio con wrapper
#   willwitcher.discord.launcherName = "Discord (WillWitcherOS)";
#   willwitcher.discord.flags = [ "--enable-features=UseOzonePlatform,WaylandWindowDecorations" ];
#   willwitcher.discord.extraEnv = { ELECTRON_TRASH = "gio"; };
#   willwitcher.discord.binName = "discord";     # override si tu flavor usa otro bin
#
# Notas:
# - Con wayland=true se exportan NIXOS_OZONE_WL=1 y ELECTRON_OZONE_PLATFORM_HINT=auto.
# - Para screenshare/audio confía en tus xdg-desktop-portal + PipeWire del sistema.
# - “vesktop” es una alternativa con Vencord integrado; si no existe en tu canal,
#   el módulo cae al paquete “discord” y te deja override vía `package`.

let
  inherit (lib) mkEnableOption mkIf mkOption types optionalString;

  cfg = config.willwitcher.discord;

  # Map flavor -> paquete (con fallback suave si no existe en el canal)
  pkgByFlavor = {
    discord = pkgs.discord or null;
    ptb     = (pkgs."discord-ptb" or null);
    canary  = (pkgs."discord-canary" or null);
    vesktop = (pkgs.vesktop or null);
  };

  chosenPkg =
    if cfg.package != null then cfg.package
    else (pkgByFlavor.${cfg.flavor} or (pkgs.discord or null));

  # Map flavor -> bin && desktop id (ajustable vía opciones)
  binByFlavor = {
    discord = "discord";
    ptb     = "discord-ptb";
    canary  = "discord-canary";
    vesktop = "vesktop";
  };

  desktopByFlavor = {
    discord = "discord.desktop";
    ptb     = "discord-ptb.desktop";
    canary  = "discord-canary.desktop";
    vesktop = "vesktop.desktop";
  };

  binNameDefault     = binByFlavor.${cfg.flavor};
  upstreamDesktopId  = desktopByFlavor.${cfg.flavor};

  # Entorno final (Wayland hints + extras)
  waylandEnv =
    if cfg.wayland then {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      GTK_USE_PORTAL = "1";
    } else { };

  mergedEnv = waylandEnv // cfg.extraEnv;

  # Wrapper para lanzar con env/flags controlados
  runName   = "ww-discord";
  runner    = pkgs.writeShellScriptBin runName ''
    set -euo pipefail
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}=${lib.escapeShellArg v}") mergedEnv)}
    exec -a ${runName} ${chosenPkg}/bin/${cfg.binName} ${lib.concatStringsSep " " cfg.flags} "$@"
  '';

  # ID del desktop que registraremos por defecto
  launcherKey = "discord-willwitcher";
  launcherDesktopId = "${launcherKey}.desktop";
  defaultDesktopId = if cfg.createLauncher then launcherDesktopId else upstreamDesktopId;

in
{
  options.willwitcher.discord = {
    enable = mkEnableOption "Enable Discord/Vesktop (managed by Home Manager).";

    flavor = mkOption {
      type = types.enum [ "discord" "ptb" "canary" "vesktop" ];
      default = "discord";
      description = "Select upstream flavor/package to install.";
    };

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "Override the Discord/Vesktop package (takes precedence over `flavor`).";
    };

    binName = mkOption {
      type = types.str;
      default = binNameDefault;
      description = "Binary name to execute (override if your package uses a different executable name).";
    };

    wayland = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Wayland/Electron Ozone hints via env vars.";
    };

    setDefaultURLHandler = mkOption {
      type = types.bool;
      default = true;
      description = "Register default handler for x-scheme-handler/discord.";
    };

    autostart = mkOption {
      type = types.bool;
      default = false;
      description = "Autostart Discord on login via systemd --user.";
    };

    createLauncher = mkOption {
      type = types.bool;
      default = true;
      description = "Create a custom launcher 'Discord (WillWitcherOS)' that uses the wrapper with your env/flags.";
    };

    launcherName = mkOption {
      type = types.str;
      default = "Discord (WillWitcherOS)";
      description = "Visible name for the custom desktop launcher.";
    };

    flags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra command-line flags for the Electron app.";
    };

    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Additional environment variables to export when starting Discord.";
    };
  };

  config = mkIf cfg.enable (mkIf (chosenPkg != null) {
    assertions = [
      {
        assertion = chosenPkg != null;
        message = "willwitcher.discord: the selected flavor/package is not available in your nixpkgs.";
      }
    ];

    # Instala el paquete elegido y el wrapper si corresponde
    home.packages =
      [ chosenPkg ] ++ lib.optionals cfg.createLauncher [ runner ];

    # Exporta variables de entorno (global a la sesión)
    home.sessionVariables = mergedEnv;

    # Desktop launcher propio (no oculta el upstream; puedes filtrar en Wofi si deseas)
    xdg.desktopEntries = lib.mkIf cfg.createLauncher {
      ${launcherKey} = {
        type = "Application";
        name = cfg.launcherName;
        genericName = "Chat & Voice";
        exec = "${runner}/bin/${runName} %U";
        terminal = false;
        categories = [ "Network" "InstantMessaging" "Chat" ];
        mimeType = [ "x-scheme-handler/discord" ];
        # Icon y WMClass aproximados por flavor
        icon = if cfg.flavor == "vesktop" then "vesktop" else "discord";
        startupWMClass = if cfg.flavor == "vesktop" then "Vesktop" else "discord";
      };
    };

    # Registrar handler de esquema
    xdg.mimeApps.defaultApplications = mkIf cfg.setDefaultURLHandler {
      "x-scheme-handler/discord" = defaultDesktopId;
    };

    # Autostart via systemd --user (respetando el mismo wrapper/env)
    systemd.user.services.willwitcher-discord = mkIf cfg.autostart {
      Unit = {
        Description = "Discord (WillWitcherOS) autostart";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${runner}/bin/${runName}";
        Restart = "on-failure";
        RestartSec = 2;
        # Exporta el mismo entorno también en el servicio
        Environment = lib.mapAttrsToList (k: v: "${k}=${v}") mergedEnv;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  });
}
