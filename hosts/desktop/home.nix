{ config, pkgs, inputs, lib, ... }:
{
  ################################################################################
  # Home Manager (user scope)
  ################################################################################

  home.username      = "willwitcher";
  home.homeDirectory = "/home/willwitcher";
  home.stateVersion  = "25.05";

  home.sessionPath = [ "$HOME/.local/bin" ];

  ################################################################################
  # Module imports (Home Manager modules from the repo)
  ################################################################################
  imports = [
  ];
  ################################################################################
  # Fonts (user-scoped)
  ################################################################################
  fonts.fontconfig.enable = true;

  ################################################################################
  # User packages
  ################################################################################
  home.packages = with pkgs; [
     ];
  ################################################################################
  # Dotfiles / assets (copy from repo to $HOME)
  ################################################################################
  home.file = {
    "Wallpapers/" = {
      source    = ../../wallpapers;
      recursive = true;   # directory
      force     = true;   # overwrite if exists
    };
    ".config/" = {
        source = ../../hosts/desktop/dotfiles/.config;
        recursive = true;
        force = true;
    };
    ".icons/" = {
        source = ../../hosts/desktop/dotfiles/.icons;
        recursive = true;
        force = true;
    };
    ".fonts/" = {
        source = ../../hosts/desktop/dotfiles/.fonts;
        recursive = true;
        force = true;
    };
     ".local/share/icons/" = {
        source = ../../hosts/desktop/dotfiles/.icons;
        recursive = true;
        force = true;
    };
    ".local/share/fonts/" = {
        source = ../../hosts/desktop/dotfiles/.fonts;
        recursive = true;
        force = true;
    };
    ".themes/" = {
        source = ../../hosts/desktop/dotfiles/.themes;
        recursive = true;
        force = true;
    };
    ".local/bin" = {
        source = ../../scripts;
        recursive = true;
        force = true;
      };
      ".mozilla" = {
        source = ../../hosts/desktop/dotfiles/.mozilla;
          recursive = true;
          force = true;
        };
	".zshrc" = {
        source = ../../hosts/desktop/dotfiles/.zshrc;
          recursive = false;
          force = true;
        };
	".zsh" = {
        source = ../../hosts/desktop/dotfiles/.zsh;
          recursive = true;
          force = true;
        };
	".local/share/applications/ww-wallpaper-picker.desktop" = {
    	source = ../../hosts/desktop/dotfiles/.desktop_files/ww-wallpaper-picker.desktop;
  	};
};

home.activation.initWallpaperCurrent =
  lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    current="${config.home.homeDirectory}/.wallpaper.current"
    if [ ! -f "$current" ]; then
      cp ${../../hosts/desktop/dotfiles/.wallpaper.default} "$current"
    fi
  '';

  ################################################################################
  # Environment variables (session)
  ################################################################################
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  ################################################################################
  # Git & GitHub CLI
  ################################################################################
  programs.git = {
    enable = true;

    # Keep original structure intact (settings.* + settings = { ... }):
    settings.user.name  = "Willwitcher";
    settings.user.email = "willgamedevelopment@gmail.com";
    settings = {
      credential.helper = "!gh auth git-credential";
      # 'https://github.com'.useHttpPath = true;
    };
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "https";
  };

  programs.home-manager.enable = true;

  ################################################################################
  # Services
  ################################################################################
  services.gnome-keyring.enable = true;
}
