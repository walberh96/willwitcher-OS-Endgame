{ config, pkgs, inputs, lib, ... }:

{
  ############################
  # Imports
  ############################
  imports = [
    ./hardware-configuration.nix
    inputs.stylix.nixosModules.stylix
  ];

  ############################
  # Boot & Kernel
  ############################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  ############################
  # Hostname, Network, Timezone
  ############################
  networking.hostName = "ww-desktop";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";

  ############################
  # Locale
  ############################
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT    = "en_US.UTF-8";
    LC_MONETARY       = "en_US.UTF-8";
    LC_NAME           = "en_US.UTF-8";
    LC_NUMERIC        = "en_US.UTF-8";
    LC_PAPER          = "en_US.UTF-8";
    LC_TELEPHONE      = "en_US.UTF-8";
    LC_TIME           = "en_US.UTF-8";
  };

  # Keyboard layout for X11/Xwayland apps
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  ############################
  # Stylix (system theming)
  ############################
  stylix = {
    enable = true;
    autoEnable = true;
    image = ../../wallpapers/images/cat.png;
    base16Scheme = ../../themes/catppuccin-mocha.yaml;
    polarity = "dark";

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

    cursor = {
      package = pkgs.catppuccin-cursors.mochaDark;
      name    = "catppuccin-mocha-dark-cursors";
      size    = 32;
    };
  };

  ############################
  # User
  ############################
  users.users.willwitcher = {
    isNormalUser = true;
    description  = "willwitcher";
    extraGroups  = [ "networkmanager" "wheel" ];
    shell        = pkgs.nushell;
  };
  environment.shells = [ pkgs.nushell ];
  programs.nushell.enable = true;

  ############################
  # Licensing
  ############################
  nixpkgs.config.allowUnfree = true;

  ############################
  # Display Manager
  ############################
  services.greetd.enable = true;
  programs.regreet.enable = true;

  ############################
  # Hyprland (Wayland compositor)
  ############################
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  ############################
  # Audio (PipeWire)
  ############################
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  ############################
  # Hardware & Security
  ############################
  hardware.bluetooth.enable = true;
  security.polkit.enable = true;

  ############################
  # XDG Portals (screen sharing, file pickers, etc.)
  ############################
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
  ];
  xdg.portal.config.common.default = [ "hyprland" "gnome" "gtk" ];

  ############################
  # Session Environment
  ############################
  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE    = "wayland";
    NIXOS_OZONE_WL      = "1";
  };

  ############################
  # Thunar + previews
  ############################
  programs.xfconf.enable     = true;
  services.gvfs.enable       = true;
  services.tumbler.enable    = true;
  programs.thunar.enable     = true;
  programs.thunar.plugins    = with pkgs.xfce; [ thunar-archive-plugin ];

  ############################
  # Gaming
  ############################
  hardware.steam-hardware.enable = true;
  programs.steam.enable          = true;
  programs.gamemode.enable       = true;

  ############################
  # nix-ld (run non-Nix binaries with missing libs)
  ############################
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    icu
  ];

  #############################
  #############################
  
  programs.gpu-screen-recorder.enable = true;

  ############################
  ############################

  ############################
  # System Packages
  ############################
  environment.systemPackages = with pkgs; [ ];

  ############################
  # Nix (features & flakes)
  ############################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  ############################
  # Home Manager (user scope)
  ############################
  home-manager = {
    useGlobalPkgs        = true;
    extraSpecialArgs     = { inherit inputs; };
    backupFileExtension  = "hm-bak";
    users.willwitcher    = import ./home.nix;
  };

  ############################
  # State Version
  ############################
  system.stateVersion = "25.05";
}

