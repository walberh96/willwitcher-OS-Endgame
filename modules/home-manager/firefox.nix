{ config, lib, pkgs, ... }:

# Firefox (Home Manager) — WillWitcherOS module
# - Stylix drives the theme (colors) for specific Firefox profiles.
# - Home Manager owns the profile (so it’s reproducible).
# - Two ad-blockers preinstalled: AdGuard AdBlocker + uBlock Origin.
# - All telemetry disabled by default.
#
# How to enable in your home.nix:
#   imports = [ (inputs.self + /modules/home-manager/firefox.nix) ];
#   willwitcher.firefox.enable = true;
#   willwitcher.firefox.profileName = "default";  # <- your chosen profile name
#
# Optional toggles (read each description below):
#   willwitcher.firefox.enableFirefoxColor = false;
#   willwitcher.firefox.enableFirefoxGnomeTheme = false;
#   willwitcher.firefox.strictETP = true;
#   willwitcher.firefox.httpsOnly = true;
#   willwitcher.firefox.resistFingerprinting = false;  # can break sites; off by default
#   willwitcher.firefox.disablePocket = true;
#   willwitcher.firefox.disableFirefoxAccounts = false; # set true if you never use Sync/Account
#
# Rebuild:
#   sudo nixos-rebuild switch --flake .#desktop
#
# Notes:
# - If you previously had pkgs.firefox in home.packages, remove it (HM manages Firefox here).
# - Stylix needs the *profile name(s)* to theme them. That’s why we pass `profileNames = [ profileName ]`.
# - Add-ons come from `pkgs.firefox-addons`. If any name ever changes, run:
#     nix search nixpkgs firefox-addons | rg -i 'ublock|adguard'
#
let
  inherit (lib) mkEnableOption mkOption mkIf types;

  cfg = config.willwitcher.firefox;

  # Convenience: privacy pref helpers
  bool = v: if v then true else false;
in
{
  options.willwitcher.firefox = {
    enable = mkEnableOption "Enable Firefox with Stylix theming and privacy defaults";

    # The Home Manager profile name you want to use/control
    profileName = mkOption {
      type = types.str;
      default = "default";
      description = "Firefox profile name managed by Home Manager (also themed via Stylix).";
    };

    # Stylix extras
    enableFirefoxColor = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Stylix's Firefox Color integration for toolbar themeing.";
    };
    enableFirefoxGnomeTheme = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Stylix's Firefox GNOME theme (GTK-like look).";
    };

    # Privacy / hardening toggles (safe defaults, see comments)
    strictETP = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Enhanced Tracking Protection = 'strict'. May break a few sites but improves privacy.";
    };
    httpsOnly = mkOption {
      type = types.bool;
      default = true;
      description = "Force HTTPS-Only mode globally (HTTP falls back with a warning).";
    };
    resistFingerprinting = mkOption {
      type = types.bool;
      default = false;
      description = "Enable privacy.resistFingerprinting (can break site layouts, canvas, window sizing).";
    };
    disablePocket = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Pocket integration and related features.";
    };
    disableFirefoxAccounts = mkOption {
      type = types.bool;
      default = false;
      description = "Disable Firefox Account/Sync UI. Turn on only if you never use Sync/Account.";
    };
  };

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;

      # Declare and own the profile via HM so we can attach settings/extensions
      profiles = {
        "${cfg.profileName}" = {
          isDefault = true;

          # ---- Extensions (preinstalled) -------------------------------------
          # Both are enabled by default. If you want only one, remove the other.
          # Running two blockers works but duplicates filtering work; keep whichever you prefer.
          extensions = with pkgs.firefox-addons; [
            ublock-origin
            adguard-adblocker
          ];

          # ---- Preferences (user.js) -----------------------------------------
          # All telemetry/experiments OFF, plus optional privacy hardening controlled by toggles above.
          settings =
            {
              # --- Telemetry / Experiments / Data reporting (ALL OFF) ---
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
              "browser.discovery.enabled" = false;                 # disable add-on recommendations
              "browser.urlbar.quicksuggest.enabled" = false;       # disable sponsored suggestions
              "browser.urlbar.suggest.quicksuggest.sponsored" = false;
              "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
              "browser.newtabpage.activity-stream.feeds.topsites" = false;
              "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
              "browser.newtabpage.activity-stream.showSponsored" = false;
              "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
              "browser.messaging-system.whatsNewPanel.enabled" = false;
              "extensions.recommendations.enabled" = false;
              "extensions.getAddons.showPane" = false;
              "network.trr.confirmation_telemetry_enabled" = false;
              "dom.ipc.plugins.reportCrashURL" = false;

              # --- Crash reporter / Normandy (experiments rollout) OFF ---
              "breakpad.reportURL" = "";
              "browser.tabs.crashReporting.sendReport" = false;
              "app.normandy.enabled" = false;
              "app.normandy.api_url" = "";

              # --- Misc sanity ---
              "browser.shell.checkDefaultBrowser" = false;
              "browser.aboutConfig.showWarning" = false;
              "signon.rememberSignons" = false;   # do not store passwords (use a manager)
              "signon.management.page.breach-alerts.enabled" = false;

              # --- Security / network prefetch toggles (safe defaults) ---
              "network.dns.disablePrefetch" = true;
              "network.predictor.enabled" = false;
              "network.prefetch-next" = false;

              # --- Pocket / FxAccounts (controlled below) ---
              "extensions.pocket.enabled" = cfg.disablePocket;
              "identity.fxaccounts.enabled" = lib.mkDefault (!cfg.disableFirefoxAccounts);

              # --- Enhanced Tracking Protection (strict/standard) ---
              # 0 = standard, 1 = strict, 2 = custom (UI variant). We'll use 1 for strict if enabled.
              "browser.contentblocking.category" = if cfg.strictETP then "strict" else "standard";

              # --- HTTPS-Only Mode ---
              "dom.security.https_only_mode" = cfg.httpsOnly;

              # --- Resist Fingerprinting (can break sites) ---
              "privacy.resistFingerprinting" = cfg.resistFingerprinting;

              # --- Do Not Track header (harmless to enable) ---
              "privacy.donottrackheader.enabled" = true;

              # --- Safe browsing (kept ON; disable at your own risk) ---
              # If you truly want them off, set these to false (not recommended):
              # "browser.safebrowsing.malware.enabled" = true;
              # "browser.safebrowsing.phishing.enabled" = true;
            };
        };
      };
    };

    # Stylix target: theme Firefox profile(s) named below.
    stylix.targets.firefox = {
      enable = true;
      profileNames = [ cfg.profileName ];
      colorTheme.enable = cfg.enableFirefoxColor;         # optional toolbar theming
      firefoxGnomeTheme.enable = cfg.enableFirefoxGnomeTheme; # optional GNOME look
    };
  };
}
