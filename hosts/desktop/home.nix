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

  ############################
    ## Import your HM modules ##
    ############################
    imports = [
      ../../modules/home-manager/hyprland.nix
      ../../modules/home-manager/waybar.nix
      ../../modules/home-manager/wofi.nix
      ../../modules/home-manager/swaync.nix
      ../../modules/home-manager/kitty.nix
      ../../modules/home-manager/starship.nix
      ../../modules/home-manager/btop.nix
      ../../modules/home-manager/zed.nix
      ../../modules/home-manager/firefox.nix
      ../../modules/home-manager/nvim.nix
      ../../modules/home-manager/zathura.nix
      ../../modules/home-manager/fzf.nix
    ];

    ############################
    ## Enable our Hyprland mod
    ############################
    willwitcher.hyprland.enable = true;
    willwitcher.waybar.enable = true;
    willwitcher.wofi.enable = true;
    willwitcher.swaync.enable = true;
    willwitcher.kitty.enable = true;
    willwitcher.starship.enable = true;
    willwitcher.btop.enable = true;
    willwitcher.fzf.enable = true;
    # ZATHURA ###
    willwitcher.zathura.enable = true;

    # Optional: make Zathura the default viewer for PDFs
    willwitcher.zathura.makeDefault = true;


    # NVIM SECTION ###
    ##################
    willwitcher.nvim.enable = true;

      # Optional quality-of-life:
      willwitcher.nvim.defaultEditor = true;
      willwitcher.nvim.viAlias = true;
      willwitcher.nvim.vimAlias = true;

      # LSPs you want (adjust to your stack):
      willwitcher.nvim.lsp.enable.python = true;
      willwitcher.nvim.lsp.enable.rust   = true;
      willwitcher.nvim.lsp.enable.web    = true;

      # Keep Neovim color-neutral and let Stylix/Kitty rule the palette…
      willwitcher.nvim.plugins.themeProvider = "none";
    #####################################################################
    # ####################################################################
    willwitcher.zed.enable = true;
    willwitcher.zed.themeFromStylix = true;
    # Optional: make it the default browser
    willwitcher.firefox = {
      enable =true;
      profileName = "willwitcher";
      makeDefault = true;
      # Añade/extiende tus extensiones declarativas aquí:
          policyExtensions = [
            { id = "uBlock0@raymondhill.net";    slug = "ublock-origin"; }
            # { id = "otra@id"; slug = "otro-slug"; }
          ];

          # (opcional) Declarar marcadores:
          # manageBookmarks = true;
          # bookmarksForce  = false;  # true para imponer la lista
          # bookmarkItems = [
          #   { name = "YouTube"; url = "https://youtube.com"; }
          #   { name = "Arch Wiki"; url = "https://wiki.archlinux.org/"; }
          # ];
    };

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
    discord
    zed-editor
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
    EDITOR = "nvim";
  };

  #####################################
  ## Git (user identity + config)
  #####################################
  programs.git = {
    enable    = true;
    settings.user.name  = "Willwitcher";
    settings.user.email = "willgamedevelopment@gmail.com";
    # For extra config use:
    # extraConfig = { init.defaultBranch = "main"; pull.rebase = false; };
    settings = {
        credential.helper = "!gh auth git-credential";
        # opcional: si quieres que Git trate cada path de GitHub como único
        # 'https://github.com'.useHttpPath = true;
      };
  };

  # si gestionas gh con HM, puedes fijar protocolo:
  programs.gh = {
    enable = true;
    settings.git_protocol = "https"; # o "ssh"
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

  services.gnome-keyring.enable = true;

  # --- Stylix per-target toggles (opt-in)
    stylix = {
      autoEnable = true; # mirror system intent: only theme what you choose

      # Íconos: Dracula para ambos modos
          icons = {
            enable  = true;                # activa el target de iconos
            package = pkgs.dracula-icon-theme;
            dark    = "Dracula";
            light   = "Dracula";
          };

          # Cursor: Catppuccin (Mocha + Mauve) a tamaño 28
          cursor = {
            package = pkgs.catppuccin-cursors.mochaDark;
            name    = "catppuccin-mocha-dark-cursors";  # ajusta el acento si quieres
            size    = 28;
          };

      targets = {
        # Terminals
        kitty.enable = true;              # kitty gets Stylix colors/fonts :contentReference[oaicite:4]{index=4}
        firefox.profileNames = ["willwitcher"];
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
