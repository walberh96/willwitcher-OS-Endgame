{ config, lib, pkgs, ... }:

# LibreWolf (via HM's Firefox module) — WillWitcherOS style
#
# What this module does:
#  - Installs and manages LibreWolf declaratively using `programs.firefox` (package swapped to LibreWolf).
#  - Declares a managed profile (name configurable).
#  - Applies privacy-focused defaults (telemetry off, HTTPS-only, strict ETP, etc.).
#  - Optionally installs add-ons (uBlock Origin, AdGuard AdBlocker).
#  - Optionally sets LibreWolf as the default browser (XDG + env var).
#  - Lets Stylix theme LibreWolf by targeting the exact profile name(s).
#
# How to enable in your home.nix:
#   imports = [ (inputs.self + /modules/home-manager/librewolf.nix) ];
#   willwitcher.librewolf.enable = true;
#   willwitcher.librewolf.profileName = "default";  # <-- your chosen profile name
#
# Optional toggles (read docstrings below and turn them on/off as needed):
#   willwitcher.librewolf.makeDefault = true;        # set as system default (XDG)
#   willwitcher.librewolf.installAddons = true;      # install add-ons listed in `addons`
#   willwitcher.librewolf.addons = with pkgs.firefox-addons; [ ublock-origin adguard-adblocker ];
#   willwitcher.librewolf.strictETP = true;          # Enhanced Tracking Protection = strict
#   willwitcher.librewolf.httpsOnly = true;          # HTTPS-Only mode
#   willwitcher.librewolf.resistFingerprinting = false;  # can break sites; off by default
#   willwitcher.librewolf.enableLetterboxing = true;     # letterboxing (best with RFP on)
#   willwitcher.librewolf.disableWebGL = true;       # safer; turn off if you need WebGL
#   willwitcher.librewolf.disablePocket = true;      # disable Pocket UI (LibreWolf ya lo desactiva en general)
#   willwitcher.librewolf.disableFirefoxAccounts = true; # LibreWolf suele no usar FxA; deja en true si no usas Sync
#   willwitcher.librewolf.bookmarksToolbar = "always";   # show bookmarks toolbar (always/never/newtab)
#   willwitcher.librewolf.variableFontSize = 20;     # UI/content default variable font size
#   willwitcher.librewolf.reuseExistingProfilePath = null; # string path if you want to reuse an existing profile
#
# Notes:
#  - Stylix cannot auto-discover profiles: you MUST list profileNames it should theme. This module does it for you.
#  - If you reuse an existing profile via `reuseExistingProfilePath`, we will point the HM profile to that path.
#  - Running two ad blockers works but duplicates filtering; keep only one if you prefer.
#
let
  inherit (lib) mkEnableOption mkOption mkIf types;

  cfg = config.willwitcher.librewolf;

  # helper to build Firefox (LibreWolf) prefs map
  # booleans and strings go straight into `profiles.${name}.settings`
  basePrefs = {
    # --- Telemetry / data reporting OFF (LibreWolf already ships hardened; we enforce here too) ---
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

    # --- Safe defaults / UX tweaks ---
    "browser.shell.checkDefaultBrowser" = false;
    "browser.aboutConfig.showWarning" = false;

    # Show bookmarks toolbar: "always" | "never" | "newtab"
    "browser.toolbars.bookmarks.visibility" = cfg.bookmarksToolbar;

    # Variable font size (content)
    "font.size.variable.x-western" = cfg.variableFontSize;

    # --- Prefetch & predictor OFF (privacy) ---
    "network.dns.disablePrefetch" = true;
    "network.predictor.enabled" = false;
    "network.prefetch-next" = false;

    # --- HTTPS-Only & ETP (some sites may break on strict/https-only) ---
    "dom.security.https_only_mode" = cfg.httpsOnly;
    # browser.contentblocking.category: "standard"|"strict"|"custom"
    "browser.contentblocking.category" = (if cfg.strictETP then "strict" else "standard");

    # --- Fingerprinting resistance ---
    "privacy.resistFingerprinting" = cfg.resistFingerprinting;
    # Letterboxing works best if RFP is on, but you can still enable it
    "privacy.resistFingerprinting.letterboxing" = cfg.enableLetterboxing;

    # --- Pocket / FxAccounts (LibreWolf typically disables these; we enforce here) ---
    "extensions.pocket.enabled" = cfg.disablePocket;
    "identity.fxaccounts.enabled" = (!cfg.disableFirefoxAccounts);

    # --- Crash reporter / Normandy OFF ---
    "breakpad.reportURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;
    "app.normandy.enabled" = false;
    "app.normandy.api_url" = "";

    # --- WebGL: disable if you prefer safety/stability ---
    "webgl.disabled" = cfg.disableWebGL;

    # --- Clear-on-shutdown (history/downloads/cookies) ---
    # Enable if you want a very ephemeral setup (may be overkill for daily browsing)
    # "privacy.clearOnShutdown.history" = true;
    # "privacy.clearOnShutdown.downloads" = true;
    # "privacy.clearOnShutdown.cookies" = true;
  };
in
{
  options.willwitcher.librewolf = {
    enable = mkEnableOption "Enable LibreWolf browser (themed by Stylix, managed by Home Manager).";

    # Declarative profile name managed by HM & themed by Stylix
    profileName = mkOption {
      type = types.str;
      default = "default";
      description = "LibreWolf profile name managed by Home Manager.";
    };

    # If you want to reuse an existing profile path, set it here (full absolute path).
    reuseExistingProfilePath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Absolute path to an existing profile directory to reuse instead of creating a new one.";
    };

    # Make LibreWolf the default browser (XDG + env var)
    makeDefault = mkOption {
      type = types.bool;
      default = true;
      description = "Set LibreWolf as the default browser for http/https/text/html and DEFAULT_BROWSER env var.";
    };

    # Add-ons management
    installAddons = mkOption {
      type = types.bool;
      default = true;
      description = "Install add-ons listed in `addons` to the managed profile.";
    };
    addons = mkOption {
      type = types.listOf types.package;
      default = with pkgs.firefox-addons; [ ublock-origin adguard-adblocker ];
      description = "Firefox add-ons packages to install into the profile.";
    };

    # Privacy / hardening toggles
    strictETP = mkOption {
      type = types.bool;
      default = true;
      description = "Enhanced Tracking Protection: 'strict' if true, else 'standard'.";
    };
    httpsOnly = mkOption {
      type = types.bool;
      default = true;
      description = "Force HTTPS-Only mode.";
    };
    resistFingerprinting = mkOption {
      type = types.bool;
      default = false;
      description = "Enable privacy.resistFingerprinting (may break some sites/features).";
    };
    enableLetterboxing = mkOption {
      type = types.bool;
      default = true;
      description = "Enable letterboxing (best paired with resistFingerprinting).";
    };
    disableWebGL = mkOption {
      type = types.bool;
      default = true;
      description = "Disable WebGL for stability/privacy (set to false if you need WebGL).";
    };
    disablePocket = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Pocket integration.";
    };
    disableFirefoxAccounts = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Firefox Account / Sync UI.";
    };

    bookmarksToolbar = mkOption {
      type = types.enum [ "always" "never" "newtab" ];
      default = "always";
      description = "Bookmarks toolbar visibility: always | never | newtab.";
    };

    variableFontSize = mkOption {
      type = types.int;
      default = 20;
      description = "Default variable font size for western scripts (content).";
    };
  };

  config = mkIf cfg.enable {
    # Use HM's Firefox module but with LibreWolf as the package
    programs.firefox = {
      enable = true;
      package = pkgs.librewolf;

      # Managed profile
      profiles = {
        "${cfg.profileName}" =
          (if cfg.reuseExistingProfilePath != null then {
            # Reuse an existing profile directory (keep your old data)
            path = cfg.reuseExistingProfilePath;
            isDefault = true;
          } else {
            # Let HM create/manage a fresh profile
            isDefault = true;
          }) // {
            # Add-ons (if enabled)
            extensions = lib.mkIf cfg.installAddons cfg.addons;

            # Preferences (user.js) — merged from toggles above
            settings = basePrefs;
          };
      };
    };

    # Stylix target for LibreWolf: theme the specified profile(s)
    stylix.targets.librewolf = {
      enable = true;
      profileNames = [ cfg.profileName ];
      # Note: We keep it minimal (enable + profileNames).
      # If Stylix later exposes colorTheme/GNOME knobs for librewolf,
      # you can add them here similarly to the Firefox target.
    };

    # Set LibreWolf as default browser (XDG + env var), if requested
    xdg.mimeApps.defaultApplications = lib.mkIf cfg.makeDefault {
      "text/html"               = "librewolf.desktop";
      "x-scheme-handler/http"   = "librewolf.desktop";
      "x-scheme-handler/https"  = "librewolf.desktop";
      "x-scheme-handler/about"  = "librewolf.desktop";
      "x-scheme-handler/unknown"= "librewolf.desktop";
    };

    home.sessionVariables = lib.mkIf cfg.makeDefault {
      DEFAULT_BROWSER = "${pkgs.librewolf}/bin/librewolf";
    };
  };
}
