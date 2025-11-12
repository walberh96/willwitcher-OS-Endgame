{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption mkIf mkMerge types mapAttrs';

  cfg = config.willwitcher.firefox;

  # Base user.js preferences (driven by options in `cfg` where applicable)
  basePrefs = {
    # --- Telemetry & reporting: OFF ---
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

    # --- UI / warnings ---
    "browser.aboutConfig.showWarning" = false;
    "browser.shell.checkDefaultBrowser" = false;

    # --- Startup & New Tab: blank ---
    "browser.startup.page" = 0; # 0 = blank
    "browser.startup.homepage" = "about:blank";
    "browser.newtabpage.enabled" = false;

    # --- Activity Stream (New Tab): suggestions/ads/telemetry OFF ---
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.newtabpage.activity-stream.telemetry" = false;
    "browser.newtabpage.activity-stream.feeds.telemetry" = false;

    # --- URL bar quicksuggest: OFF ---
    "browser.urlbar.quicksuggest.enabled" = false;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;

    # --- Bookmarks toolbar visibility & base font size (option-driven) ---
    "browser.toolbars.bookmarks.visibility" = cfg.bookmarksToolbar;
    "font.size.variable.x-western" = cfg.variableFontSize;

    # --- Prefetch / predictor: OFF ---
    "network.dns.disablePrefetch" = true;
    "network.predictor.enabled" = false;
    "network.prefetch-next" = false;

    # --- HTTPS-Only & Enhanced Tracking Protection (ETP) ---
    "dom.security.https_only_mode" = cfg.httpsOnly;
    "browser.contentblocking.category" =
      (if cfg.strictETP then "strict" else "standard");

    # --- Fingerprinting resistance (optional) ---
    "privacy.resistFingerprinting" = cfg.resistFingerprinting;

    # --- Pocket / Firefox Accounts (option-driven) ---
    "extensions.pocket.enabled" = (!cfg.disablePocket);
    "extensions.recommendations.enabled" = false;
    "extensions.getAddons.showPane" = false;
    "identity.fxaccounts.enabled" = (!cfg.disableFirefoxAccounts);

    # --- Crash reporter: OFF ---
    "breakpad.reportURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;

    # --- DRM (Widevine): ON ---
    "media.eme.enabled" = true;
    "media.gmp-widevinecdm.enabled" = true;

    # --- Global Privacy Control (GPC) ---
    "privacy.globalprivacycontrol.enabled" = true;
    "privacy.globalprivacycontrol.functionality.enabled" = true;

    # --- Native vertical tabs (FF >= 136) ---
    "sidebar.revamp" = true;
    "sidebar.verticalTabs" = true;

    # --- Keep externally installed extensions enabled ---
    "extensions.autoDisableScopes" = 0;

    # --- Allow userChrome.css / userContent.css (optional) ---
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  };

  # Build a single ExtensionSettings policy entry for one extension
  mkPolicyExt = ext:
    let
      # Defaults per extension entry
      default = {
        installation_mode = "force_installed";
        private_browsing  = true;
        default_area      = "menupanel";
      };
      merged = default // (removeAttrs ext [ "id" "slug" ]);
      url    = "https://addons.mozilla.org/firefox/downloads/latest/${ext.slug}/latest.xpi";
    in
    merged // { install_url = url; };

  # Convert the declarative list to the attrset that policies.json expects
  extSettingsAttrset =
    lib.listToAttrs (map (ext: { name = ext.id; value = mkPolicyExt ext; }) cfg.policyExtensions);

in
{
  ##############################################################################
  # OPTIONS
  ##############################################################################
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
      description = "Set Firefox as the default browser using XDG and a session env var.";
    };

    # Stylix toggles
    enableFirefoxColor = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Stylix's Firefox Color toolbar theming.";
    };

    enableFirefoxGnomeTheme = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Stylix's Firefox GNOME theme (GTK-like look).";
    };

    # Privacy toggles
    strictETP = mkOption {
      type = types.bool;
      default = false; # Standard by default
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
      description = "Enable RFP (may break some layouts/features).";
    };

    disablePocket = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Pocket integration.";
    };

    disableFirefoxAccounts = mkOption {
      type = types.bool;
      default = false;
      description = "Disable Firefox Accounts / Sync UI.";
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

    # --- Extensions via policies (AMO) ----------------------------------------
    policyExtensions = mkOption {
      type = types.listOf (types.attrsOf types.anything);
      default = [
        { id = "uBlock0@raymondhill.net"; slug = "ublock-origin"; }
      ];
      example = lib.literalExpression ''
        [
          { id = "some-ext@id"; slug = "amo-slug-here"; }
          { id = "another@id";  slug = "another-slug"; private_browsing = false; }
        ]
      '';
      description = ''
        Declarative list of extensions installed via Firefox policies (ExtensionSettings).
        Each item must include:
          - id   : the extension ID (from about:support or extensions.json)
          - slug : the AMO slug to build the latest.xpi URL
        Optional keys (override defaults): installation_mode, private_browsing, default_area, install_url.
      '';
    };

    # --- Bookmarks management --------------------------------------------------
    manageBookmarks = mkOption {
      type = types.bool;
      default = false;
      description = "If true, manage bookmarks declaratively.";
    };

    bookmarksForce = mkOption {
      type = types.bool;
      default = false;
      description = "If true, Home Manager replaces existing bookmarks each rebuild.";
    };

    # Simple flat bookmarks (name/url). For complex structures, use `bookmarksRaw`.
    bookmarkItems = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption { type = types.str; description = "Bookmark title."; };
          url  = mkOption { type = types.str; description = "Bookmark URL.";   };
        };
      });
      default = [ ];
      description = "Simple flat bookmarks (toolbar by default).";
    };

    # Advanced: pass the HM bookmarks submodule as-is. If set, takes precedence.
    bookmarksRaw = mkOption {
      type = types.nullOr types.attrs;
      default = null;
      description = "Raw HM bookmarks submodule (advanced: directories, separators, etc.).";
    };
  };

  ##############################################################################
  # CONFIG
  ##############################################################################
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
            # user.js preferences
            settings = basePrefs;

            # Keep externally installed extensions enabled
            extensions.force = true;

            # Declarative bookmarks (optional)
            bookmarks = mkIf cfg.manageBookmarks (
              if cfg.bookmarksRaw != null then
                cfg.bookmarksRaw
              else
                {
                  force = cfg.bookmarksForce;
                  bookmarks = map (b: { name = b.name; url = b.url; }) cfg.bookmarkItems;
                }
            );
          };
      };

      # Enterprise policies (policies.json)
      policies = {
        # Extensions from AMO (force_installed + latest.xpi)
        ExtensionSettings = extSettingsAttrset;

        # New Tab / Home: blank, plus DRM enabled
        NewTabPage = false;
        Homepage = { StartPage = "homepage"; URL = "about:blank"; };
        EncryptedMediaExtensions = { Enabled = true; };
      };
    };

    # Stylix theming for this Firefox profile
    stylix.targets.firefox = {
      enable = true;
      profileNames = [ cfg.profileName ];
      colorTheme.enable = cfg.enableFirefoxColor;
      firefoxGnomeTheme.enable = cfg.enableFirefoxGnomeTheme;
    };

    # Default browser integration (XDG + env var)
    xdg.mimeApps.defaultApplications = mkIf cfg.makeDefault {
      "text/html"              = "firefox.desktop";
      "x-scheme-handler/http"  = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };

    home.sessionVariables = mkIf cfg.makeDefault {
      DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
    };
  };
}
