{ config, pkgs, inputs, lib, ... }:

{
  ################################################################################
  # Home Manager (user scope)
  ################################################################################

  home.username      = "willwitcher";
  home.homeDirectory = "/home/willwitcher";
  home.stateVersion  = "25.05";

  ################################################################################
  # Module imports (Home Manager modules from the repo)
  ################################################################################
  imports = [
    ../../modules/home-manager/hyprland.nix
    ../../modules/home-manager/waybar.nix
    ../../modules/home-manager/wofi.nix
    ../../modules/home-manager/swaync.nix
    ../../modules/home-manager/kitty.nix
    ../../modules/home-manager/starship.nix
    ../../modules/home-manager/btop.nix
    ../../modules/home-manager/firefox.nix
    ../../modules/home-manager/zathura.nix
    ../../modules/home-manager/fzf.nix
    ../../modules/home-manager/vesktop.nix
    ../../modules/home-manager/nvf-willwitcher.nix
    ../../modules/home-manager/tmux.nix
  ];

  ################################################################################
  # Feature toggles (custom modules)
  ################################################################################
  willwitcher.hyprland.enable = true;
  willwitcher.waybar.enable   = true;
  willwitcher.wofi.enable     = true;
  willwitcher.swaync.enable   = true;
  willwitcher.kitty.enable    = true;
  willwitcher.starship.enable = true;
  willwitcher.btop.enable     = true;
  willwitcher.fzf.enable      = true;
  willwitcher.nvim.enable     = true;
  willwitcher.tmux.enable     = true;
  willwitcher.tmux.whichKey.enable = true;

  # Zathura (PDF viewer)
  willwitcher.zathura.enable      = true;
  willwitcher.zathura.makeDefault = true;

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
  # Force Kitty font size (kept as-is)
  programs.kitty.font.size = lib.mkForce 16;

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
    wofi hyprpaper hyprlock hyprpicker hyprshot wl-clipboard
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

  ################################################################################
  # Zsh (plugins and initialization)
  ################################################################################
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # Built-in syntax highlighting from HM
    syntaxHighlighting.enable = true;

    # 1) Initialize completion and add nix-zsh-completions to $fpath
    completionInit = ''
      fpath=(${pkgs.nix-zsh-completions}/share/zsh/site-functions $fpath)
      autoload -U compinit
      compinit
    '';

    # 2) Load plugins AFTER compinit, using known paths
    initContent = ''
      # --- zsh-autosuggestions ---
      if [[ -f ${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        source ${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
      elif [[ -f ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      fi

      # --- zsh-fzf-tab (requires compinit) ---
      if [[ -f ${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh ]]; then
        source ${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
      elif [[ -f ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh ]]; then
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      elif [[ -f ${pkgs.zsh-fzf-tab}/share/zsh-fzf-tab/fzf-tab.plugin.zsh ]]; then
        source ${pkgs.zsh-fzf-tab}/share/zsh-fzf-tab/fzf-tab.plugin.zsh
      fi

      # Helpful style for fzf-tab: switch match groups with ',' and '.'
      zstyle ':fzf-tab:*' switch-group ',' '.'
    '';
  };

  programs.starship.enable = true;
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

    targets = {
      kitty.enable                = true;
      firefox.profileNames        = [ "willwitcher" ];
      hyprland.enable             = true;
      hyprland.hyprpaper.enable   = true;
      waybar.enable               = true;
      wofi.enable                 = true;
      zathura.enable              = true;
      gtk.enable                  = true;
      vesktop.enable              = true;
      nvf.enable                  = true;
    };
  };
}

