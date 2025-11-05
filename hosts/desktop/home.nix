{ config, pkgs,inputs, ... }:

{
  ################################################################################
  # Home Manager (user scope)
  ################################################################################

  home.username      = "willwitcher";
  home.homeDirectory = "/home/willwitcher";
  home.stateVersion  = "25.05";

  imports = [
        inputs.nvf.homeManagerModules.default
        inputs.nvf.homeManagerModules.default
    ../../modules/home-manager/hyprland.nix
    ../../modules/home-manager/waybar.nix
    ../../modules/home-manager/wofi.nix
    ../../modules/home-manager/swaync.nix
    ../../modules/home-manager/kitty.nix
    ../../modules/home-manager/starship.nix
    ../../modules/home-manager/btop.nix
    ../../modules/home-manager/zed.nix
    ../../modules/home-manager/firefox.nix
    ../../modules/home-manager/zathura.nix
    ../../modules/home-manager/fzf.nix
    ../../modules/home-manager/vesktop.nix
  ];

  willwitcher.hyprland.enable = true;
  willwitcher.waybar.enable   = true;
  willwitcher.wofi.enable     = true;
  willwitcher.swaync.enable   = true;
  willwitcher.kitty.enable    = true;
  willwitcher.starship.enable = true;
  willwitcher.btop.enable     = true;
  willwitcher.fzf.enable      = true;

  # Zathura
  willwitcher.zathura.enable       = true;
  willwitcher.zathura.makeDefault  = true;

  # Zed
  willwitcher.zed.enable        = true;
  willwitcher.zed.themeFromStylix = true;

  # VESKTOP
  programs.vesktop = {
      enable = true;
      # Opcional: algunos ajustes útiles
      settings = {
        tray = true;
        minimizeToTray = true;
        hardwareAcceleration = true;
        discordBranch = "stable";
      };
  };

  #NVF
  programs.nvf = {
    enable = true;
    defaultEditor = true;      # exporta EDITOR=“nvim”
    enableManpages = true;     # podrás usar: man 5 nvf
    settings = {
      vim = {
        viAlias = true;
        vimAlias = true;

        # File tree — nvim-tree
        filetree.nvimTree.enable = true;

        # Git — Neogit (módulo NVF)
        # Si tu build dice que la opción no existe, usa el fallback de la sección 6.
        git.neogit.enable = true;

        # Markdown — LSP/format + render-markdown
        languages.markdown = {
          enable = true;        # treesitter, etc.
          lsp.enable = true;    # marksman
          format.enable = true; # (puedes ajustar el tipo después)
          extensions.render-markdown-nvim.enable = true;
        };

        # Rust — todo lo necesario
        languages.rust = {
          enable = true;
          lsp.enable = true;        # rust-analyzer via rustaceanvim
          format.enable = true;     # rustfmt
          debugger.enable = true;   # DAP (CodeLLDB)
        };
      };
    };
  };



  # Firefox (declarativo)
  willwitcher.firefox = {
    enable       = true;
    profileName  = "willwitcher";
    makeDefault  = true;
    policyExtensions = [
      { id = "uBlock0@raymondhill.net"; slug = "ublock-origin"; }
    ];
  };

  #####################################
  ## Fonts (user-scoped)
  #####################################
  fonts.fontconfig.enable = true;

  #####################################
  ## User packages
  #####################################
  home.packages = with pkgs; [
    zed-editor signal-desktop mpv zathura qimgv libreoffice
    wofi hyprpaper hyprlock hyprpicker hyprshot wl-clipboard
    ntfs3g udiskie swaynotificationcenter waybar blueman
    mpvpaper xarchiver
    p7zip unar xz zstd bzip3 gzip gnutar libarchive
    zoxide ripgrep-all fd fzf jq lsd bat gh nb pass gnupg
    fastfetch btop git libnotify gpu-screen-recorder-gtk lutris
    nerd-fonts.hack noto-fonts noto-fonts-emoji font-awesome
    # Rust
      rustc cargo rustfmt clippy rust-analyzer lldb

      # Markdown
      marksman
      deno        # (si luego eliges "deno_fmt" como formateador)
      # o en su lugar: nodePackages.prettier  # si prefieres prettier
  ];

  home.file = { };

  #####################################
  ## Environment variables (user session)
  #####################################
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  #####################################
  ## Git
  #####################################
  programs.git = {
    enable = true;
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

  #####################################
  ## Zsh
  #####################################
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # Mantienes syntax highlighting de HM
    syntaxHighlighting.enable = true;

    # 1) compinit + nix-zsh-completions al fpath (ANTES de fzf-tab)
    completionInit = ''
      fpath=(${pkgs.nix-zsh-completions}/share/zsh/site-functions $fpath)
      autoload -U compinit
      compinit
    '';

    # 2) Cargar plugins DESPUÉS de compinit, usando rutas alternativas
    initContent = ''
      # --- zsh-autosuggestions ---
      if [[ -f ${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        source ${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
      elif [[ -f ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      fi

      # --- zsh-fzf-tab (requiere compinit cargado) ---
      if [[ -f ${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh ]]; then
        source ${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
      elif [[ -f ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh ]]; then
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      elif [[ -f ${pkgs.zsh-fzf-tab}/share/zsh-fzf-tab/fzf-tab.plugin.zsh ]]; then
        source ${pkgs.zsh-fzf-tab}/share/zsh-fzf-tab/fzf-tab.plugin.zsh
      fi

      # Opcional: un estilo útil para fzf-tab
      zstyle ':fzf-tab:*' switch-group ',' '.'
    '';
  };

  programs.starship.enable = true;
  programs.home-manager.enable = true;

  services.gnome-keyring.enable = true;

  # --- Stylix (usuario): SIN cursor aquí; el cursor lo maneja el sistema.
  stylix = {
    autoEnable = true;

    # Iconos (si quieres mantenerlos en HM)
    icons = {
      enable  = true;
      package = pkgs.dracula-icon-theme;
      dark    = "Dracula";
      light   = "Dracula";
    };

    targets = {
      kitty.enable = true;
      firefox.profileNames = [ "willwitcher" ];
      hyprland.enable = true;
      hyprland.hyprpaper.enable = true;
      waybar.enable = true;
      wofi.enable = true;
      zathura.enable = true;
      gtk.enable = true;
      vesktop.enable = true;
      nvf.enable = true;
    };
  };
}
