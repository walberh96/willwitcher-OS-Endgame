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
    # Apps
    signal-desktop mpv zathura qimgv libreoffice
    hyprpaper hyprlock hyprpicker hyprshot wl-clipboard
    ntfs3g udiskie swaynotificationcenter waybar blueman
    mpvpaper xarchiver cliphist
    # Archivers / compression tools
    p7zip unar xz zstd bzip3 gzip gnutar libarchive
    # CLI utilities
    zoxide ripgrep-all ripgrep fd fzf jq lsd bat gh nb pass gnupg
    fastfetch btop git libnotify gpu-screen-recorder-gtk lutris
    # Fonts (user scope)
    nerd-fonts.hack noto-fonts noto-fonts-emoji font-awesome
    # Wayland helpers
    slurp
    # Rust toolchain
    rustc cargo rustfmt clippy rust-analyzer lldb gcc binutils pkg-config
    # Audio control
    pwvucontrol
    # AI (terminal client)
    gemini-cli
    # Screen recording

    # Markdown tooling
    marksman
    deno
    # or: nodePackages.prettier  # if you prefer Prettier instead of Deno fmt

    #Under testing for now
    wlogout
    yazi
    rofi
    wezterm
    neovim
    swww
    vesktop
    firefox
    networkmanagerapplet

  gpu-screen-recorder   # the recorder backend (command: gpu-screen-recorder)
  jq
  ffmpeg
  v4l-utils             # probe webcam formats (command: v4l2-ctl)
  procps                # process utilities (commands: pgrep, pkill)
  gawk                  # arithmetic/formatting (command: awk)
  gnugrep                  # pattern matching (command: grep)
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
 };

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
 ################################################################################
  # Stylix (user scope) — cursor is handled at the system level
################################################################################
  stylix = {
    autoEnable = true;

    # Icons (kept under Home Manager if you prefer user-scoped icon theme)
    icons = {
      enable  = true;
      package = pkgs.dracula-icon-theme;
      dark    = "Dracula";
      light   = "Dracula";
    };
  };
}
