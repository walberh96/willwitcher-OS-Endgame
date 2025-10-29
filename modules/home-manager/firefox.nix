{ config, lib, pkgs, ... }:

# Firefox (Home Manager) — WillWitcherOS style
#
# What this module does:
# - Manages Firefox declaratively using Home Manager (programs.firefox).
# - Declares one managed profile with a predefined name (default: "default").
# - Stylix themes that profile (you must list the profile name for Stylix).
# - Privacy-friendly defaults (telemetry OFF, HTTPS-Only ON, ETP strict).
# - Optional: set Firefox as the system default browser (XDG + env var).
#
# How to enable (home.nix):
#   imports = [ (inputs.self + /modules/home-manager/firefox.nix) ];
#   willwitcher.firefox.enable = true;
#   willwitcher.firefox.profileName = "default";  # or any name you prefer
#
# After rebuild:
#   - Start Firefox once. Home Manager will have created the profile for you.
#   - Check about:profiles → the Default Profile should match your chosen name.
#
# Notes:
# - We do NOT hardcode extensions here to avoid attr availability mismatches.
#   Later, you can add uBlock / AdGuard declaratively (I can wire it up when you want).
# - Stylix will color Firefox as long as `profileNames = [ "yourProfileName" ]` is set.

let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.willwitcher.firefox;

  # Base privacy & UX prefs written into user.js for the managed profile
  basePrefs = {
    # --- Telemetry / data reporting OFF ---
    "app.shield.optoutstudies.enabled" = false;
    "browser.ping-centre.telemetry" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.healthreport.service.enabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.server" = "";
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.updatePing.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    "toolkit.coverage.enabled" = false;
    "toolkit.coverage.opt-out" = true;
    "extensions.recommendations.enabled" = false;
    "extensions.getAddons.showPane" = false;

    # --- New Tab / sponsored content OFF ---
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

    # --- URL bar suggestions OFF ---
    "browser.urlbar.quicksuggest.enabled" = false;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;

    # --- UX sanity ---
    "browser.shell.checkDefaultBrowser" = false;
    "browser.aboutConfig.showWarning" = false;

    # Bookmarks toolbar visibility: "always" | "never" | "newtab"
    "browser.toolbars.bookmarks.visibility" = cfg.bookmarksToolbar;

    # Default content font size (western scripts)
    "font.size.variable.x-western" = cfg.variableFontSize;

    # --- Prefetch / predictor OFF ---
    "network.dns.disablePrefetch" = true;
    "network.predictor.enabled" = false;
    "network.prefetch-next" = false;

    # --- HTTPS-Only & Enhanced Tracking Protection ---
    "dom.security.https_only_mode" = cfg.httpsOnly;
    # "standard" | "strict" | "custom"
    "browser.contentblocking.category" =
      (if cfg.strictETP then "strict" else "standard");

    # --- Fingerprinting resistance (can break some sites/features) ---
    "privacy.resistFingerprinting" = cfg.resistFingerprinting;

    # --- Pocket / Firefox Accounts ---
    "extensions.pocket.enabled"   = (!cfg.disablePocket);
    "identity.fxaccounts.enabled" = (!cfg.disableFirefoxAccounts);

    # --- Crash reporter / Normandy OFF ---
    "breakpad.reportURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;
    "app.normandy.enabled" = false;
    "app.normandy.api_url" = "";
  };
in
{
  options.willwitcher.firefox = {
    enable = mkEnableOption "Enable Firefox (themed by Stylix, managed by Home Manager).";

    # Predefined profile name managed by Home Manager (and themed by Stylix).
    profileName = mkOption {
      type = types.str;
      default = "default";
      description = "Firefox profile name to create/manage (and to theme via Stylix).";
    };

    # Optional: reuse an existing profile directory (absolute path).
    # Leave as null to let HM create a fresh one for you.
    reuseExistingProfilePath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Absolute path to an existing Firefox profile to reuse (see about:profiles).";
    };

    # Make Firefox the default browser (XDG + DEFAULT_BROWSER env var).
    makeDefault = mkOption {
      type = types.bool;
      default = true;
      description = "Set Firefox as the default browser using XDG and env var.";
    };

    # Optional extra theming knobs from Stylix:
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
    strictETP = mkOption { type = types.bool; default = true;  description = "Enhanced Tracking Protection: strict if true."; };
    httpsOnly = mkOption { type = types.bool; default = true;  description = "Force HTTPS-Only mode."; };
    resistFingerprinting = mkOption { type = types.bool; default = false; description = "Enable RFP (may break layouts/features)."; };
    disablePocket = mkOption { type = types.bool; default = true; description = "Disable Pocket integration."; };
    disableFirefoxAccounts = mkOption { type = types.bool; default = false; description = "Disable Firefox Account / Sync UI."; };

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

      # Declare the managed profile. If reuseExistingProfilePath is null,
      # Home Manager will create and manage a fresh profile for you.
      profiles = {
        "${cfg.profileName}" =
          (if cfg.reuseExistingProfilePath != null then {
            path = cfg.reuseExistingProfilePath;  # reuse existing profile data
            isDefault = true;
          } else {
            isDefault = true;                     # let HM create/manage one
          }) // {
            # Preferences (user.js)
            settings = basePrefs;

            # Extensions intentionally omitted here; add later if you want declarative add-ons.
            extensions = {
                          force = true;        # requerido si defines 'extensions.settings' o reemplazas el set
                          #packages = addons;   # instala uBlock Origin y AdGuard si tu nixpkgs tiene 'firefox-addons'
                          # settings = {       # opcional: políticas por extensión (policies.json / ExtensionSettings)
                          #   "uBlock0@raymondhill.net" = {
                          #     installation_mode = "allowed";
                          #     # Nota: esto NO configura opciones internas de uBlock; es para políticas de instalación/actualización.
                          #   };
                          #   "adguardadblocker@adguard.com" = {
                          #     installation_mode = "allowed";
                          #   };
                          # };
                        };
          };
      };
    };

    # Stylix: theme Firefox by exact profile name
    stylix.targets.firefox = {
      enable = true;                           # not strictly required if autoEnable, but explicit is clear
      profileNames = [ cfg.profileName ];      # REQUIRED so Stylix knows which profile(s) to theme
      colorTheme.enable = cfg.enableFirefoxColor;         # optional
      firefoxGnomeTheme.enable = cfg.enableFirefoxGnomeTheme; # optional
    };

    # Default browser wiring (XDG + env var)
    xdg.mimeApps.defaultApplications = mkIf cfg.makeDefault {
      "text/html"                = "firefox.desktop";
      "x-scheme-handler/http"    = "firefox.desktop";
      "x-scheme-handler/https"   = "firefox.desktop";
      "x-scheme-handler/about"   = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
    home.sessionVariables = mkIf cfg.makeDefault {
      DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
    };
  };
}
