{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    inputs.stylix.nixosModules.stylix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "ww-desktop";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";

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

  # Layout de teclado para apps X11/Xwayland
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  ########################
  # Stylix (sistema)
  ########################
  stylix = {
    enable = true;
    autoEnable = true;
    image = ./wallpapers/kenpachi.png;
    base16Scheme = ../../themes/catppuccin-mocha.yaml;

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
      package = pkgs.bibata-cursors;
      name    = "Bibata-Modern-Ice";
      size    = 24;
    };
  };

  ########################
  # Usuario
  ########################
  users.users.willwitcher = {
    isNormalUser = true;
    description  = "willwitcher";
    extraGroups  = [ "networkmanager" "wheel" ];
    shell        = pkgs.zsh;
  };
  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  ########################
  # Display Manager: LY
  ########################
  services.displayManager.ly.enable = true;

  # Asegura sesión por defecto a Hyprland
  services.displayManager.defaultSession = "hyprland";
  # Por si LY necesita ver el .desktop de Hyprland explícitamente:
  services.displayManager.sessionPackages = [ pkgs.hyprland ];

  ########################
  # Hyprland
  ########################
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  ########################
  # Audio (PipeWire)
  ########################
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  hardware.bluetooth.enable = true;
  security.polkit.enable = true;

  ########################
  # XDG Portals
  ########################
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
  ];
  xdg.portal.config.common.default = [ "hyprland" "gnome" "gtk" ];

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  ########################
  # Thunar + previews
  ########################
  programs.xfconf.enable = true;
  services.gvfs.enable   = true;
  services.tumbler.enable = true;
  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs.xfce; [ thunar-archive-plugin ];

  ########################
  # Gaming
  ########################
  hardware.steam-hardware.enable = true;
  programs.steam.enable = true;
  programs.gamemode.enable = true;

  ########################
  # nix-ld
  ########################
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ icu ];

  environment.systemPackages = with pkgs; [ ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  home-manager = {
    useGlobalPkgs   = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "hm-bak";
    users.willwitcher = import ./home.nix;
  };

  system.stateVersion = "25.05";
}
