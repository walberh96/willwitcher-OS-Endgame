{ config, lib, pkgs, ... }:

# Discord (Home Manager) — WillWitcherOS style
#
# What this module does:
# - Instala Discord (o alternativa: Vesktop/WebCord/Discordo).
# - Crea un wrapper con flags para Wayland/Electron por defecto.
# - Opción para autostart y para registrar el scheme "discord://".
# - No toca colores/temas; eso lo maneja tu stack (Stylix/terminal).
#
# How to enable in your home.nix:
#   imports = [ (inputs.self + /modules/home-manager/discord.nix) ];
#   willwitcher.discord.enable = true;
#
# Optional knobs:
#   willwitcher.discord.client = "discord";    # "discord" | "vesktop" | "webcord" | "discordo"
#   willwitcher.discord.preferWayland = true;  # añade flags Electron Wayland
#   willwitcher.discord.extraFlags = [ "--disable-gpu-sandbox" ];
#   willwitcher.discord.autoStart = false;     # autostart al iniciar sesión
#   willwitcher.discord.setSchemeHandler = true; # maneja x-scheme-handler/discord
#   willwitcher.discord.desktopName = "Discord (WillWitcherOS)"; # nombre visible

let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.willwitcher.discord;

  pkg =
    let c = cfg.client;
    in if c == "vesktop" then pkgs.vesktop
       else if c == "webcord" then pkgs.webcord
       else if c == "discordo" then pkgs.discordo
       else pkgs.discord;

  wrapperName = "willwitcher-discord";

  waylandFlags = [
    "--enable-features=UseOzonePlatform,WaylandWindowDecorations"
    "--ozone-platform=wayland"
  ];

  waylandEnv = ''
    export ELECTRON_OZONE_PLATFORM_HINT=auto
    export NIXOS_OZONE_WL=1
    export GTK_USE_PORTAL=1
  '';

  wrapper = pkgs.writeShellApplication {
    name = wrapperName;
    text = ''
      set -e
      ${lib.optionalString cfg.preferWayland waylandEnv}
      exec ${lib.getExe pkg} ${lib.escapeShellArgs (lib.optionals cfg.preferWayland waylandFlags ++ cfg.extraFlags)} "$@"
    '';
  };

  desktopId = "willwitcher-discord";

  wmClass =
    if cfg.client == "vesktop" then "Vesktop"
    else if cfg.client == "webcord" then "WebCord"
    else if cfg.client == "discord" then "discord"
    else null; # discordo (TUI) no necesita WMClass

  iconName =
    if cfg.client == "vesktop" then "vesktop"
    else if cfg.client == "webcord" then "webcord"
    else "discord";
in
{
  options.willwitcher.discord = {
    enable = mkEnableOption "Enable Discord (managed by Home Manager).";

    client = mkOption {
      type = types.enum [ "discord" "vesktop" "webcord" "discordo" ];
      default = "discord";
      description = "Discord client to install: official Discord, Vesktop (Vencord), WebCord, or Discordo (TUI).";
    };

    preferWayland = mkOption {
      type = types.bool;
      default = true;
      description = "Start with Electron Wayland flags (ozone + decorations). Recommended on Hyprland/Wayland.";
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ "--ignore-gpu-blocklist" ];
      description = "Additional CLI flags passed to the client (Electron).";
    };

    autoStart = mkOption {
      type = types.bool;
      default = false;
      description = "Autostart Discord on login (creates an autostart .desktop).";
    };

    setSchemeHandler = mkOption {
      type = types.bool;
      default = true;
      description = "Register handler for x-scheme-handler/discord to this desktop entry.";
    };

    desktopName = mkOption {
      type = types.str;
      default = "Discord (WillWitcherOS)";
      description = "Name shown in launchers for the custom desktop entry.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkg wrapper ];

    xdg.desktopEntries.${desktopId} = {
      name = cfg.desktopName;
      genericName = "Chat and Communities";
      exec = "${lib.getExe wrapper} %U";
      terminal = (cfg.client == "discordo");
      categories = [ "Network" "InstantMessaging" "Chat" ];
      icon = iconName;
      type = "Application";

      # Claves extra del .desktop (correcto en HM: usar `settings`)
      settings = lib.optionalAttrs (wmClass != null) {
        StartupWMClass = wmClass;
      };
    };

    # Autostart opcional
    home.file.".config/autostart/${desktopId}.desktop" = mkIf cfg.autoStart {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=${cfg.desktopName}
        Exec=${lib.getExe wrapper} --start-minimized
        X-GNOME-Autostart-enabled=true
        X-KDE-autostart-after=panel
        Icon=${iconName}
        Categories=Network;InstantMessaging;Chat;
        ${lib.optionalString (wmClass != null) "StartupWMClass=${wmClass}"}
      '';
    };

    # Registrar scheme handler (para discord://)
    xdg.mimeApps.defaultApplications = mkIf cfg.setSchemeHandler {
      "x-scheme-handler/discord" = "${desktopId}.desktop";
    };
  };
}
