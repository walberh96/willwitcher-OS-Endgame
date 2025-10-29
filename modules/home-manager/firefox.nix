{ config, lib, pkgs, ... }:

# Firefox (Home Manager) — WillWitcherOS style (2025-10)
#
# Cambios clave:
# - Home & New Tab: página en blanco (about:blank).
# - Pestañas verticales nativas activadas (Firefox >= 136).
# - DRM (Widevine) ON.
# - ETP por defecto en "standard" (opción para cambiar a strict).
# - Global Privacy Control (GPC) ON.
# - Telemetría/pings del New Tab OFF.
# - uBlock Origin instalado con 'force = true' para que HM controle extensiones.
#
let
  inherit (lib) mkEnableOption mkOption mkIf types optionals;

  cfg = config.willwitcher.firefox;

  # Intentamos resolver uBlock Origin desde pkgs.firefox-addons; si no existe, la lista queda vacía.
  uboPkg =
    if (pkgs ? firefox-addons && pkgs.firefox-addons ? ublock-origin)
    then pkgs.firefox-addons.ublock-origin
    else null;

  basePrefs = {
    # --- Telemetry / reporting OFF ---
    "app.normandy.api_url" = "";
    "app.normandy.enabled" = false;
    "app.shield.optoutstudies.enabled" = false;
    "browser.ping-centre.telemetry" = false;
    "datareporting.healthreport.service.enabled" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "toolkit.coverage.enabled" = false;
    "toolkit.coverage.opt-out" = true;
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.server" = "";
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.updatePing.enabled" = false;

    # --- UI / avisos ---
    "browser.aboutConfig.showWarning" = false;
    "browser.shell.checkDefaultBrowser" = false;

    # --- Página de inicio y nueva pestaña: en blanco ---
    # 0 = blank, 1 = home, 3 = restore session
    "browser.startup.page" = 0;
    "browser.startup.homepage" = "about:blank";
    "browser.newtabpage.enabled" = false;

    # Activity Stream (New Tab) sugerencias/ads OFF + telemetría OFF
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.newtabpage.activity-stream.telemetry" = false;
    "browser.newtabpage.activity-stream.feeds.telemetry" = false;

    # --- URLbar quicksuggest OFF ---
    "browser.urlbar.quicksuggest.enabled" = false;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;

    # --- Barra de marcadores + fuente base ---
    "browser.toolbars.bookmarks.visibility" = cfg.bookmarksToolbar;
    "font.size.variable.x-western" = cfg.variableFontSize;

    # --- Prefetch / predictor OFF ---
    "network.dns.disablePrefetch" = true;
    "network.predictor.enabled" = false;
    "network.prefetch-next" = false;

    # --- HTTPS-Only & ETP ---
    "dom.security.https_only_mode" = cfg.httpsOnly;
    # "standard" | "strict" | "custom"
    "browser.contentblocking.category" = (if cfg.strictETP then "strict" else "standard");

    # --- Fingerprinting resistance (opcional) ---
    "privacy.resistFingerprinting" = cfg.resistFingerprinting;

    # --- Pocket / Firefox Accounts ---
    "extensions.pocket.enabled" = (!cfg.disablePocket);
    "identity.fxaccounts.enabled" = (!cfg.disableFirefoxAccounts);
    "extensions.recommendations.enabled" = false;
    "extensions.getAddons.showPane" = false;

    # --- Crash reporter / Normandy OFF ---
    "breakpad.reportURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;

    # --- DRM (Widevine) ON ---
    "media.eme.enabled" = true;
    "media.gmp-widevinecdm.enabled" = true;

    # --- Global Privacy Control (GPC) ---
    "privacy.globalprivacycontrol.enabled" = true;
    "privacy.globalprivacycontrol.functionality.enabled" = true;

    # --- Pestañas verticales nativas (FF >= 136) ---
    "sidebar.revamp" = true;
    "sidebar.verticalTabs" = true;

    # --- No deshabilitar extensiones instaladas por HM ---
    "extensions.autoDisableScopes" = 0;

    # --- (opcional, útil si usas userChrome/userContent) ---
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  };
in
{
  options.willwitcher.firefox = {
    enable = mkEnableOption "Enable Firefox (themed by Stylix, managed by Home Manager).";

    profileName = mkOption {
      type = types.str;
      default = "default";
      description = "Firefox profile name to create/manage (and to theme via Stylix).";
    };

    reuseExistingProfilePath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Absolute path to an existing Firefox profile to reuse (see about:profiles).";
    };

    makeDefault = mkOption {
      type = types.bool;
      default = true;
      description = "Set Firefox as the default browser using XDG and env var.";
    };

    # Stylix toggles
    enableFirefoxColor = mkOption {
      type = types.bool;
      default = true;
      description = "Also enable Stylix's Firefox Color toolbar theming.";
    };
    enableFirefoxGnomeTheme = mkOption {
      type = types.bool;
      default = true;
      description = "Also enable Stylix's Firefox GNOME theme (GTK-like look).";
    };

    # Privacy toggles
    strictETP = mkOption {
      type = types.bool;
      default = false;  # Standard por defecto (puedes poner true para Strict)
      description = "Enhanced Tracking Protection: strict if true.";
    };
    httpsOnly = mkOption {
      type = types.bool;
      default = true;
      description = "Force HTTPS-Only mode.";
    };
    resistFingerprinting = mkOption {
      type = types.bool;
      default = false;
      description = "Enable RFP (may break layouts/features).";
    };
    disablePocket = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Pocket integration.";
    };
    disableFirefoxAccounts = mkOption {
      type = types.bool;
      default = false;
      description = "Disable Firefox Account / Sync UI.";
    };

    bookmarksToolbar = mkOption {
      type = types.enum [ "always" "never" "newtab" ];
      default = "always";
      description = "Bookmarks toolbar visibility.";
    };

    variableFontSize = mkOption {
      type = types.int;
      default = 20;
      description = "Default variable font size for western scripts (page content).";
    };
  };

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;

      profiles = {
        "${cfg.profileName}" =
          (if cfg.reuseExistingProfilePath != null then {
            path = cfg.reuseExistingProfilePath;
            isDefault = true;
          } else {
            isDefault = true;
          })
          // {
            # Preferencias → user.js
            settings = basePrefs;

            # Extensiones declarativas (HM controla la lista)
            extensions = {
              force = true;                          # <- sobrescribe las extensiones existentes
              packages = optionals (uboPkg != null) [ uboPkg ];  # uBlock Origin si está disponible
              # settings = { "uBlock0@raymondhill.net" = { installation_mode = "allowed"; }; }; # opcional
            };
          };
      };
    };

    # Stylix: tematizar por nombre de perfil exacto
    stylix.targets.firefox = {
      enable = true;
      profileNames = [ cfg.profileName ];
      colorTheme.enable = cfg.enableFirefoxColor;
      firefoxGnomeTheme.enable = cfg.enableFirefoxGnomeTheme;
    };

    # Default browser wiring (XDG + env var)
    xdg.mimeApps.defaultApplications = mkIf cfg.makeDefault {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };

    home.sessionVariables = mkIf cfg.makeDefault {
      DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
    };

    # Aviso si no se encontró uBlock Origin en el canal actual
    warnings = lib.mkIf (uboPkg == null) [
      "Firefox: uBlock Origin no está disponible en pkgs.firefox-addons para este canal; no se instalará ninguna extensión. (extensions.force = true seguirá aplicando el control de la lista)."
    ];
  };
}
