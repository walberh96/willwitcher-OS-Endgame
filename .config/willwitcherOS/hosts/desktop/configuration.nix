{ config, pkgs, inputs, lib, ... }:

{
  ############################
  # Imports
  ############################
  imports = [
    /etc/nixos/hardware-configuration.nix
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

  ############################
  # Keyboard layout (X11/Xwayland)
  ############################
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  ############################
  # User
  ############################
  users.users.willwitcher = {
    isNormalUser = true;
    description  = "willwitcher";
    extraGroups  = [ "networkmanager" "wheel" "plugdev" ];
    shell        = pkgs.zsh;

    # Per-user packages (from user_packages.nix)
    packages = import ./user_packages.nix { inherit pkgs; };
  };

  programs.zsh.enable = true;

  ############################
  # Licensing
  ############################
  nixpkgs.config.allowUnfree = true;

  ############################
  # Display Manager
  ############################
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.ly.enableGnomeKeyring = true;
  services.displayManager.ly.enable = true;
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
  # XDG Portals
  ############################
  xdg.portal = {
  enable = true;
  extraPortals = with pkgs; [
    	xdg-desktop-portal-hyprland
    	xdg-desktop-portal-gtk
  ];
  config.Hyprland.default = [ "hyprland" "gtk" ];
  };

  ############################
  # Icons and Fonts
  ############################
  xdg.icons.enable = true;
  fonts.fontconfig.enable = true;

  ############################
  # Session Environment
  ############################
  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE    = "wayland";
    NIXOS_OZONE_WL      = "1";
    EDITOR              = "nvim";
  };

  # Ensure ~/.local/bin is in PATH
  environment.localBinInPath = true;

  ############################
  # Gaming
  ############################
  hardware.steam-hardware.enable = true;
  programs.steam.enable          = true;
  programs.gamemode.enable       = true;

  ############################
  # nix-ld
  ############################
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    icu
  ];

  ############################
  # GPU Screen Recorder
  ############################
  programs.gpu-screen-recorder.enable = true;

  ############################
  # System Packages (all users)
  ############################
  environment.systemPackages =
    import ./system_packages.nix { inherit pkgs; };

  ############################
  # Nix (features & flakes)
  ############################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  ############################
  # QMK / Keychron
  ############################
  hardware.keyboard.qmk.enable = true;
  hardware.keyboard.qmk.keychronSupport = true;

  ############################
  # Udev packages
  ############################
  services.udev.packages = with pkgs; [
    headsetcontrol
    keychron-udev-rules
    via
  ];

  ############################
  # State Version
  ############################
  system.stateVersion = "25.05";
}

