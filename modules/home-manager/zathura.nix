{ config, lib, pkgs, ... }:

# Zathura (Home Manager) — WillWitcherOS style
#
# What this module does:
# - Enables Zathura declaratively via Home Manager.
# - Keeps colors unopinionated so Stylix/GTK own the palette.
# - Provides clean defaults (clipboard integration, persistence).
# - Lets you set Zathura as default PDF viewer (XDG).
# - Optional backend toggles (mupdf / poppler) and extra formats (djvu, ps).
#
# How to enable in your home.nix:
#   imports = [ (inputs.self + /modules/home-manager/zathura.nix) ];
#   willwitcher.zathura.enable = true;
#
# Optional knobs:
#   willwitcher.zathura.makeDefault = true;       # make Zathura default for PDFs
#   willwitcher.zathura.backend     = "mupdf";    # or "poppler"
#   willwitcher.zathura.enableDjvu  = true;       # zathura-djvu
#   willwitcher.zathura.enablePs    = true;       # zathura-ps
#   willwitcher.zathura.extraOptions = { ... };   # inline zathurarc options
#   willwitcher.zathura.extraConfig  = '' ... ''; # raw zathurarc text
#
# Notes:
# - We intentionally do NOT set color keys like default-bg/fg, statusbar colors, etc.
#   GTK theming (Stylix) will take care of the visuals.
# - If your nixpkgs doesn’t provide separate plugin packages, just leave the
#   backend toggles as-is; Zathura will still run. If you need specific formats,
#   enable the toggles below (and adjust if your channel uses different names).

let
  inherit (lib) mkEnableOption mkIf mkOption types optionals;

  cfg = config.willwitcher.zathura;

  # Backend / format packages (toggleable). These names are common in recent nixpkgs.
  # If your channel differs, you can comment some out or rename accordingly.
  backendPkgs =
    (if cfg.backend == "mupdf" then [ pkgs.zathura-pdf-mupdf ] else [ pkgs.zathura-pdf-poppler ]);

  formatPkgs =
    (optionals cfg.enableDjvu [ pkgs.zathura-djvu ])
    ++ (optionals cfg.enablePs [ pkgs.zathura-ps ]);

in
{
  options.willwitcher.zathura = {
    enable = mkEnableOption "Enable Zathura (managed by Home Manager).";

    makeDefault = mkOption {
      type = types.bool;
      default = true;
      description = "Set Zathura as the default handler for application/pdf via XDG.";
    };

    backend = mkOption {
      type = types.enum [ "mupdf" "poppler" ];
      default = "mupdf";
      description = "PDF backend plugin to use (mupdf is fast; poppler can be more compatible).";
    };

    enableDjvu = mkOption {
      type = types.bool;
      default = true;
      description = "Install the DjVu plugin (zathura-djvu).";
    };

    enablePs = mkOption {
      type = types.bool;
      default = true;
      description = "Install the PostScript plugin (zathura-ps).";
    };

    extraOptions = mkOption {
      type = types.attrsOf (types.oneOf [ types.bool types.int types.str ]);
      default = {
        # Clipboard integration: copy selections to the Wayland/X11 clipboard
        "selection-clipboard" = "clipboard";

        # Persist bookmarks and history (sqlite is the default DB; enabled by default)
        "database" = "sqlite";

        # Smooth(ish) navigation defaults (tweak to taste)
        "scroll-step" = 70;         # pixels per scroll step
        "zoom-step"   = 10;         # percent per zoom step

        # UX: show file name in title bar only (cleaner)
        "window-title-basename" = true;

        # Recolor is OFF by default because Stylix/GTK already handles palette
        "recolor" = false;
      };
      description = ''
        Map of Zathura options written to zathurarc.
        Keep colors unset so Stylix/GTK own the palette. You can still add
        any key you’d use in zathurarc here (e.g. "adjust-open" = "width").
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Raw zathurarc lines appended after options. Use for mappings or advanced tweaks.
        Example:
          map <C-f> toggle_fullscreen
          set recolor-keephue true
      '';
    };
  };

  config = mkIf cfg.enable {
    # Install Zathura + desired backends/formats
    home.packages = [ pkgs.zathura ] ++ backendPkgs ++ formatPkgs;

    programs.zathura = {
      enable = true;

      # Do NOT hardcode colors; let Stylix/GTK theme the app.
      options = cfg.extraOptions;

      # For non-key/value settings or custom mappings
      extraConfig = cfg.extraConfig;
    };

    # Make Zathura the default PDF viewer (unless you opt out)
    xdg.mimeApps.defaultApplications = mkIf cfg.makeDefault {
      "application/pdf" = "org.pwmt.zathura.desktop";
    };

    # If you ever want explicit Stylix integration for Zathura and your Stylix version
    # exposes a dedicated target, you could enable it here. We keep this commented to
    # avoid eval errors across channels. GTK theming should be enough.
    #
    # stylix.targets.zathura.enable = true;
  };
}
