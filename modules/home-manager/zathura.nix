{ config, lib, pkgs, ... }:

# Zathura (Home Manager) — WillWitcherOS style (bundled plugins)
#
# What this module does:
# - Installs and manages Zathura via Home Manager.
# - Assumes your nixpkgs `zathura` package already bundles PDF/DjVu/PS backends.
# - Does NOT hardcode colors; GTK/ Stylix control the palette.
# - Lets you set Zathura as the default PDF handler.
# - Lets you pass extra Zathura options and raw config/mappings.
#
# How to enable in your home.nix:
#   imports = [ (inputs.self + /modules/home-manager/zathura.nix) ];
#   willwitcher.zathura.enable = true;
#
# Optional knobs:
#   willwitcher.zathura.makeDefault = true;       # make Zathura default for PDFs
#   willwitcher.zathura.extraOptions = { ... };   # key/value options into zathurarc
#   willwitcher.zathura.extraConfig  = '' ... ''; # raw zathurarc lines (mappings, etc.)
#
# Notes:
# - We intentionally do NOT set color keys (default-fg/bg, statusbar, …).
#   GTK theming via Stylix will handle look & feel.
# - If algún día cambias de canal a uno que NO traiga plugins integrados,
#   podemos reintroducir toggles para `zathuraPlugins.*`.

let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.willwitcher.zathura;
in
{
  options.willwitcher.zathura = {
    enable = mkEnableOption "Enable Zathura (managed by Home Manager).";

    makeDefault = mkOption {
      type = types.bool;
      default = true;
      description = "Set Zathura as the default handler for application/pdf via XDG.";
    };

    extraOptions = mkOption {
      type = types.attrsOf (types.oneOf [ types.bool types.int types.str ]);
      default = {
        # Clipboard integration: copy selections to the Wayland/X11 clipboard
        "selection-clipboard" = "clipboard";

        # Persist bookmarks and history (sqlite is the default DB)
        "database" = "sqlite";

        # Smooth-ish navigation defaults (tweak to taste)
        "scroll-step" = 70;     # pixels per scroll step
        "zoom-step"   = 10;     # percent per zoom step

        # Title: show only file name (cleaner)
        "window-title-basename" = true;

        # Recolor OFF by default — Stylix/GTK already drive the palette
        "recolor" = false;
      };
      description = ''
        Map of Zathura options written to zathurarc.
        Keep colors unset so Stylix/GTK own the palette. You can still add
        any key you'd normally put in zathurarc here (e.g. "adjust-open" = "width").
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
    # Just install zathura; your nixpkgs bundles the plugins already.
    home.packages = [ pkgs.zathura ];

    programs.zathura = {
      enable = true;
      options = cfg.extraOptions;   # key/value options
      extraConfig = cfg.extraConfig;# raw lines (mappings)
    };

    # Make Zathura the default PDF viewer if requested
    xdg.mimeApps.defaultApplications = mkIf cfg.makeDefault {
      "application/pdf" = "org.pwmt.zathura.desktop";
    };

    # If tu Stylix expone un target específico para Zathura en tu canal,
    # podríamos habilitarlo aquí. En la mayoría de canales basta con GTK.
    # stylix.targets.zathura.enable = true;  # ← déjalo comentado salvo que exista ese target.
  };
}
