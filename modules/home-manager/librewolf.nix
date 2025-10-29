{ config, lib, pkgs, ... }:

# LibreWolf (managed via Home Manager's Firefox module) — WillWitcherOS style
#
# What this module does:
# - Installs and manages LibreWolf declaratively (programs.firefox with package = pkgs.librewolf).
# - Declares one managed profile (name is configurable).
# - Applies privacy-focused defaults (all telemetry off, HTTPS-Only, strict ETP, etc.).
# - Lets Stylix theme LibreWolf by targeting the exact profile name(s).
# - Can set LibreWolf as system default browser (XDG + DEFAULT_BROWSER env).
#
# How to enable (home.nix):
#   imports = [ (inputs.self + /modules/home-manager/librewolf.nix) ];
#   willwitcher.librewolf.enable = true;
#   willwitcher.librewolf.profileName = "default";
#
# Optional toggles (see options below):
#   willwitcher.librewolf.makeDefault = true;
#   willwitcher.librewolf.strictETP = true;
#   willwitcher.librewolf.httpsOnly = true;
#   willwitcher.librewolf.resistFingerprinting = false;   # may break sites/features
#   willwitcher.librewolf.enableLetterboxing = true;      # best with RFP on
#   willwitcher.librewolf.disableWebGL = true;            # set false if you need WebGL
#   willwitcher.librewolf.disablePocket = true;           # LibreWolf usually ships without Pocket
#   willwitcher.librewolf.disableFirefoxAccounts = true;  # disable Sync/Account UI
#   willwitcher.librewolf.bookmarksToolbar = "always";    # "always" | "never" | "newtab"
#   willwitcher.librewolf.variableFontSize = 20;          # content default variable font size
#   willwitcher.librewolf.reuseExistingProfilePath = null # set to existing profile path to reuse data
#
# NOTE on add-ons:
# - Removed here on purpose (you hit a 'firefox-addons' attribute error).
# - Later, you can add extensions via either:
#   (A) NUR (rycee) add-ons:  programs.firefox.profiles."<name>".extensions = with pkgs.nur.repos.rycee; [ firefox-addons.ublock-origin ];
#   (B) nixpkgs' firefox-addons set (if available in your pin): with pkgs.firefox-addons; [ ublock-origin ];
#   (C) Raw XPI URLs with fetchurl + buildFirefoxXpiAddon (more advanced).
#
let
  inherit (lib) mkEnableOption mkOption mkIf types;

  cfg = config.willwitcher.librewolf;

  # Base privacy & UX prefs (written to user.js for the managed profile)
  basePrefs = {
    # --- Telemetry / reporting: OFF ---
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

    # --- UX sanity ---
    "browser.shell.checkDefaultBrowser" = false;
    "browser.aboutConfig.showWarning" = false;

    # Bookmarks toolbar: "always" | "never" | "newtab"
    "browser.toolbars.bookmarks.visibility" = cfg.bookmarksToolbar;

    # Default content font size
    "font.size.variable.x-western" = cfg.variableFontSize;

    # --- Prefetch / predictor: OFF ---
    "network.dns.disablePrefetch" = true;
    "network.predictor.enabled" = false;
    "network.prefetch-next" = false;

    # --- HTTPS-Only & ETP ---
    "dom.security.https_only_mode" = cfg.httpsOnly;
    # "standard" | "strict" | "custom"
    "browser.contentblocking.category" =
      (if cfg.strictETP then "strict" else "standard");

    # --- Fingerprinting resistance & letterboxing ---
    "privacy.resistFingerprinting" = cfg.resistFingerprinting;
    "privacy.resistFingerprinting.letterboxing" = cfg.enableLetterboxing;

    # --- Pocket / Firefox Accounts ---
    "extensions.pocket.enabled" = !cfg.disablePocket;              # disable → set false
    "identity.fxaccounts.enabled" = (!cfg.disableFirefoxAccounts); # disable → set false

    # --- Crash reporter / Normandy: OFF ---
    "breakpad.reportURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;
    "app.normandy.enabled" = false;
    "app.normandy.api_url" = "";

    # --- WebGL ---
    "webgl.disabled" = cfg.disableWebGL;

    # --- Optional clear-on-shutdown (commented; enable if you want ephemeral browsing) ---
    # "privacy.clearOnShutdown.history" = true;
    # "privacy.clearOnShutdown.downloads" = true;
    # "privacy.clearOnShutdown.cookies" = true;
  };
in
{
  options.willwitcher.librewolf = {
    enable = mkEnableOption "Enable LibreWolf (themed by Stylix, managed by Home Manager).";

    profileName = mkOption {
      type = types.str;
      default = "default";
      description = "LibreWolf profile name managed by Home Manager (also used by Stylix).";
    };

    reuseExistingProfilePath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Absolute path to an existing profile to reuse (check about:profiles).";
    };

    makeDefault = mkOption {
      type = types.bool;
      default = true;
      description = "Make LibreWolf the default browser via XDG and DEFAULT_BROWSER env var.";
    };

    # Privacy / hardening toggles
    strictETP = mkOption {
      type = types.bool; default = true;
      description = "Enhanced Tracking Protection: 'strict' if true, else 'standard'.";
    };
    httpsOnly = mkOption {
      type = types.bool; default = true;
      description = "Force HTTPS-Only mode.";
    };
    resistFingerprinting = mkOption {
      type = types.bool; default = false;
      description = "Enable privacy.resistFingerprinting (can break sites/features).";
    };
    enableLetterboxing = mkOption {
      type = types.bool; default = true;
      description = "Enable letterboxing (works best with RFP on).";
    };
    disableWebGL = mkOption {
      type = types.bool; default = true;
      description = "Disable WebGL (set to false if you need WebGL apps).";
    };
    disablePocket = mkOption {
      type = types.bool; default = true;
      description = "Disable Pocket integration UI/features.";
    };
    disableFirefoxAccounts = mkOption {
      type = types.bool; default = true;
      description = "Disable Firefox Account / Sync UI.";
    };

    bookmarksToolbar = mkOption {
      type = types.enum [ "always" "never" "newtab" ];
      default = "always";
      description = "Bookmarks toolbar visibility.";
    };

    variableFontSize = mkOption {
      type = types.int; default = 20;
      description = "Default variable font size for western scripts (page content).";
    };
  };

  config = mkIf cfg.enable {
    # Install and manage LibreWolf via HM's Firefox module
    programs.firefox = {
      enable = true;
      package = pkgs.librewolf;

      profiles = {
        "${cfg.profileName}" =
          (if cfg.reuseExistingProfilePath != null then {
            path = cfg.reuseExistingProfilePath;  # reuse old profile data
            isDefault = true;
          } else {
            isDefault = true;                     # let HM create/manage one
          }) // {
            # Preferences go to user.js
            settings = basePrefs;
          };
      };
    };

    # Stylix: theme LibreWolf profiles by name (required so Stylix knows where to apply)
    stylix.targets.librewolf = {
      enable = true;
      profileNames = [ cfg.profileName ];
    };

    # Make LibreWolf the default browser (XDG + env var)
    xdg.mimeApps.defaultApplications = mkIf cfg.makeDefault {
      "text/html"                = "librewolf.desktop";
      "x-scheme-handler/http"    = "librewolf.desktop";
      "x-scheme-handler/https"   = "librewolf.desktop";
      "x-scheme-handler/about"   = "librewolf.desktop";
      "x-scheme-handler/unknown" = "librewolf.desktop";
    };

    home.sessionVariables = mkIf cfg.makeDefault {
      DEFAULT_BROWSER = "${pkgs.librewolf}/bin/librewolf";
    };
  };
}
