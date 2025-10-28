{ config, pkgs, ... }:

{
  ################################################################################
  # Home Manager (user scope)
  # - User packages and fonts (user-scoped)
  # - Dotfiles and per-user program configs (zsh, starship, git, etc.)
  # - Environment variables for the user session
  ################################################################################

  home.username      = "willwitcher";
  home.homeDirectory = "/home/willwitcher";

  # Pin HM features; update only after reading HM release notes.
  home.stateVersion = "25.05";

  #####################################
  ## Fonts (user-scoped)
  ## Enable fontconfig for user and install fonts here.
  ## NOTE: Using noto-fonts-emoji (fixes emoji rendering).
  #####################################
  fonts.fontconfig.enable = true;

  #####################################
  ## User packages (apps, CLIs, utilities)
  ## Prefer installing here rather than system-wide.
  #####################################
  home.packages = with pkgs; [
    # GUI / desktop apps
    zed-editor
    firefox
    signal-desktop
    mpv
    zathura
    qimgv
    libreoffice
    wofi
    hyprpaper
    hyprlock
    hyprpicker
    hyprshot
    wl-clipboard
    kitty
    ntfs3g
    udiskie
    swaynotificationcenter
    mangohud
    protontricks
    wineWowPackages.stable
    pwvucontrol
    networkmanagerapplet
    wofi-emoji
    waybar
    blueman
    mpvpaper
    xarchiver

    # Archives / compression tools
    p7zip
    unar
    xz
    zstd
    bzip3
    gzip
    gnutar
    libarchive

    # Dev / CLI tools
    zoxide
    ripgrep-all
    fd
    fzf
    jq
    lsd
    bat
    gh
    nb
    pass
    gnupg
    neovim
    fastfetch
    btop
    git
    libnotify
    gpu-screen-recorder-gtk
    lutris

    # Fonts (user-scoped)
    nerd-fonts.hack
    noto-fonts
    noto-fonts-emoji   # <-- correct package for emoji
    font-awesome
  ];

  # Example of managing dotfiles (disabled for now).
  home.file = {
    # ".config/myapp/config.toml".text = "…";
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  #####################################
  ## Environment variables (user session)
  #####################################
  home.sessionVariables = {
    # Make sure this is an actual editor in PATH (e.g., "zed" or "nvim").
    # If you intended Zed, consider: EDITOR = "zed";
    EDITOR = "zeditor";
  };

  #####################################
  ## Git (user identity + config)
  #####################################
  programs.git = {
    enable    = true;
    userName  = "Willwitcher";
    userEmail = "willgamedevelopment@gmail.com";
    # For extra config use:
    # extraConfig = { init.defaultBranch = "main"; pull.rebase = false; };
  };

  #####################################
  ## Zsh (interactive shell config)
  ## NixOS provides the login shell + minimal /etc/zshrc;
  ## HM owns your ~/.zshrc, plugins, aliases, theme, etc.
  #####################################
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    # Put your aliases, prompt tweaks, and exports here.
    # initExtra = ''
    #   alias ls="lsd -alh"
    # '';
  };

  #####################################
  ## Starship prompt
  #####################################
  programs.starship.enable = true;

  #####################################
  ## Let Home Manager manage itself
  #####################################
  programs.home-manager.enable = true;

  # --- Stylix per-target toggles (opt-in)
    stylix = {
      autoEnable = true; # mirror system intent: only theme what you choose

      targets = {
        # Terminals
        kitty.enable = true;              # kitty gets Stylix colors/fonts :contentReference[oaicite:4]{index=4}

        # Compositor / wallpaper
        hyprland.enable = true;           # Hyprland colors where applicable :contentReference[oaicite:5]{index=5}
        hyprland.hyprpaper.enable = true; # sets hyprpaper to your Stylix wallpaper :contentReference[oaicite:6]{index=6}

        # Panels & launchers
        waybar.enable = true;             # can also addCss if you want extra rules :contentReference[oaicite:7]{index=7}
        wofi.enable = true;               # launcher theming via Stylix :contentReference[oaicite:8]{index=8}

        # Editors/viewers
        neovim.enable = true;             # Stylix-curated base16 for Neovim/NixVim :contentReference[oaicite:9]{index=9}
        zathura.enable = true;            # PDF viewer theming :contentReference[oaicite:10]{index=10}

        # GTK
        gtk.enable = true;                # match GTK apps to the scheme (icons/cursor via Stylix options)
      };
    };

}
