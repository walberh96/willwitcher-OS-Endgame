{ config, lib, pkgs, ... }:

# Zathura (Home Manager) — WillWitcherOS style (bundled plugins)
#
# What this module provides:
# - Installs and manages Zathura via Home Manager.
# - Assumes nixpkgs' `zathura` already bundles PDF/DjVu/PS backends.
# - Does NOT hardcode colors; GTK/Stylix own the palette.
# - Can set Zathura as the default PDF handler.
# - Lets you pass extra Zathura options and raw config/mappings.

let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.willwitcher.zathura;
in
{
  ################################################################################
  # OPTIONS
  ################################################################################
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

        # Recolor OFF by default — GTK/Stylix already drive the palette
        "recolor" = false;
      };
      description = ''
        Map of Zathura options written to zathurarc.
        Keep colors unset so GTK/Stylix own the palette. You can still add
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

  ################################################################################
  # CONFIG
  ################################################################################
  config = mkIf cfg.enable {
    # Install zathura; nixpkgs bundles the plugins already.
    home.packages = [ pkgs.zathura ];

    programs.zathura = {
      enable      = true;
      options     = cfg.extraOptions;   # key/value options → zathurarc
      extraConfig = cfg.extraConfig;    # raw lines (mappings/tweaks)
    };

    # Make Zathura the default PDF viewer if requested.
    xdg.mimeApps.defaultApplications = mkIf cfg.makeDefault {
      "application/pdf" = "org.pwmt.zathura.desktop";
    };

    # If your Stylix channel exposes a dedicated Zathura target, you can enable it:
    # stylix.targets.zathura.enable = true;
  };
}

