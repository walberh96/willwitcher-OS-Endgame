{ config, pkgs, inputs, ... }:

{
  ################################################################################
  # NixOS (system scope)
  # - Login shell, users, kernel, networking, time/locale
  # - System services (PipeWire, polkit, portals)
  # - Display manager + Hyprland
  # - System integrations (Thunar + GVFS/Tumbler/XFConf)
  # - Steam/gamemode, nix-ld
  # - Home Manager wiring (but NOT user config)
  ################################################################################

  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    inputs.stylix.nixosModules.stylix   # ← Stylix system module
  ];

  #####################################
  ## Boot and kernel
  #####################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  #####################################
  ## Host, networking and time
  #####################################
  networking.hostName = "ww-desktop";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";

  #####################################
  ## Locale
  #####################################
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS       = "en_US.UTF-8";
    LC_IDENTIFICATION= "en_US.UTF-8";
    LC_MEASUREMENT   = "en_US.UTF-8";
    LC_MONETARY      = "en_US.UTF-8";
    LC_NAME          = "en_US.UTF-8";
    LC_NUMERIC       = "en_US.UTF-8";
    LC_PAPER         = "en_US.UTF-8";
    LC_TELEPHONE     = "en_US.UTF-8";
    LC_TIME          = "en_US.UTF-8";
  };

  # XKB layout for Xwayland/X11 clients (Wayland compositor still sets its own).
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  #####################################
  ## Stylix
  #####################################
  # --- Stylix: define the global theme once at the system level
    stylix = {
      enable = true;                        # turn Stylix on system-wide
      autoEnable = true;                   # we will opt-in per target in HM (your preference)
      image = ./wallpapers/kenpachi.png;      # wallpaper path (change to your actual file)

      # Color scheme: use a Base16 file (e.g., Catppuccin Mocha)
      # You can swap to any ${pkgs.base16-schemes}/share/themes/*.yaml
      base16Scheme = "../../themes/circus.yaml";

      # Fonts used across apps; Stylix ensures availability + fontconfig
      fonts = {
        serif = {
          package = pkgs.nerd-fonts.hack;
          name    = "Hack Nerd Font";
        };
        sansSerif = {
          package = pkgs.nerd-fonts.hack;
          name    = "Hack Nerd Font";
        };
        monospace = {
          package = pkgs.nerd-fonts.hack;
          name    = "Hack Nerd Font Mono";
        };
        emoji = {
          package = pkgs.noto-fonts-emoji;
          name    = "Noto Color Emoji";
        };
      };
    };


  #####################################
  ## Users
  #####################################
  users.users.willwitcher = {
    isNormalUser = true;
    description  = "willwitcher";
    extraGroups  = [ "networkmanager" "wheel" ];
    # Login shell MUST be declared in NixOS (edits /etc/passwd).
    shell        = pkgs.zsh;
    # packages = [ ];  # Leave empty; user apps come from Home Manager.
  };

  # Required so zsh is recognized as a valid login shell.
  environment.shells = [ pkgs.zsh ];

  # REQUIRED by NixOS when setting a user's login shell to zsh.
  # Provides a minimal /etc/zshrc with a correct PATH for login shells.
  programs.zsh.enable = true;

  # Allow unfree packages system-wide (Steam, etc.)
  nixpkgs.config.allowUnfree = true;

  #####################################
  ## Display manager + Hyprland compositor
  #####################################
  services.displayManager.ly.enable = true;
  # For DMs that honor it; harmless to keep with ly.
  services.displayManager.defaultSession = "hyprland";

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  #####################################
  ## Audio (PipeWire)
  #####################################
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable          = true;
    alsa.enable     = true;
    alsa.support32Bit = true;
    pulse.enable    = true;
    wireplumber.enable = true;
  };

  #####################################
  ## Bluetooth
  #####################################
  hardware.bluetooth.enable = true;

  #####################################
  ## Polkit (GUI privilege prompts)
  #####################################
  security.polkit.enable = true;

  #####################################
  ## XDG Portals (Wayland/Hyprland)
  #####################################
  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
  ];

  #####################################
  ## File manager integrations (system services)
  ## These are system-scoped so Thunar previews/mounts work everywhere.
  #####################################
  programs.xfconf.enable = true;
  services.gvfs.enable   = true;
  services.tumbler.enable = true;

  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs.xfce; [
    thunar-archive-plugin
  ];

  #####################################
  ## Gaming (needs system toggles)
  #####################################
  hardware.steam-hardware.enable = true;
  programs.steam.enable = true;
  programs.gamemode.enable = true;

  #####################################
  ## nix-ld (for non-Nix binaries missing libs)
  #####################################
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    icu # e.g., required by some VS Code/Dotnet scenarios
  ];

  #####################################
  ## System packages
  ## Keep minimal; prefer Home Manager for user apps.
  #####################################
  environment.systemPackages = with pkgs; [ ];

  #####################################
  ## Nix settings
  #####################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  #####################################
  ## Home Manager (wire-up only)
  ## The actual user config is in ./home.nix
  #####################################
  home-manager = {
    useGlobalPkgs   = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "hm-bak";
    users.willwitcher = import ./home.nix;
  };

  #####################################
  ## Version pins (do not bump lightly)
  #####################################
  system.stateVersion = "25.05";
}
