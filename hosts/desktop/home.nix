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
    ../../modules/home-manager/hyprland.nix
    ../../modules/home-manager/firefox.nix
  ];

  ################################################################################
  # Feature toggles (custom modules)
  ################################################################################
  willwitcher.hyprland.enable = true;

  ################################################################################
  # Vesktop (Discord client fork)
  ################################################################################
  programs.vesktop = {
    enable = true;
    # Optional quality-of-life settings
    settings = {
      tray                 = true;
      minimizeToTray       = true;
      hardwareAcceleration = true;
      discordBranch        = "stable";
    };

};

  ################################################################################
  # Firefox (declarative profile through custom module)
  ################################################################################
  willwitcher.firefox = {
    enable       = true;
    profileName  = "willwitcher";
    makeDefault  = true;
    policyExtensions = [
      { id = "uBlock0@raymondhill.net"; slug = "ublock-origin"; }
    ];
  };

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
    mpvpaper xarchiver
    # Archivers / compression tools
    p7zip unar xz zstd bzip3 gzip gnutar libarchive
    # CLI utilities
    zoxide ripgrep-all fd fzf jq lsd bat gh nb pass gnupg
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
    wl-screenrec
    # Markdown tooling
    marksman
    deno
    # or: nodePackages.prettier  # if you prefer Prettier instead of Deno fmt

    #Under testing for now
    wlogout
    yazi

    wezterm
    starship
    zed-editor
    walker
 ];
  ################################################################################
  # Dotfiles / assets (copy from repo to $HOME)
  ################################################################################
  home.file = {
    "Wallpapers/live" = {
      source    = ../../wallpapers/live;
      recursive = true;   # directory
      force     = true;   # overwrite if exists
    };
    "Wallpapers/images" = {
      source    = ../../wallpapers/images;
      recursive = true;
      force     = true;
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

  # 2) Start Elephant (Walker's backend) in your user session
  systemd.user.services.elephant = {
    Unit = { Description = "Elephant backend for Walker"; };
    Service = {
      ExecStart = "${inputs.elephant.packages.${pkgs.system}.default}/bin/elephant";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

    # 3) Preload Walker as a background service (GTK app service)
    systemd.user.services.walker = {
      Unit = {
        Description = "Walker service (preload)";
        After = [ "elephant.service" ];
        Wants = [ "elephant.service" ];
      };
      Service = {
        ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
        Restart = "on-failure";
        # Optional safety guard if you notice leaks:
        # MemoryMax = "512M";
      };
      Install.WantedBy = [ "default.target" ];
    };

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

    targets = {
      firefox.profileNames        = [ "willwitcher" ];
      gtk.enable                  = true;
      vesktop.enable              = true;
    };
  };
}
