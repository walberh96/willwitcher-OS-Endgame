{ config, pkgs,inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Bluetooth
    hardware.bluetooth.enable = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "ww-desktop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.willwitcher = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "willwitcher";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Add zsh to the environment
  environment.shells = [ pkgs.zsh ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

services.displayManager.ly.enable = true;
services.displayManager.defaultSession = "hyprland";
programs.hyprland = {
enable = true;
xwayland.enable = true ;
};


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
system.stateVersion = "25.05"; # Did you read the comment?


nix.settings.experimental-features = ["nix-command" "flakes"];
home-manager = {
	extraSpecialArgs = { inherit inputs;};
	users = {
		"willwitcher" = import ./home.nix;
		};
	useGlobalPkgs = true;
	};

# Steam + hardware
hardware.steam-hardware.enable = true;
programs.steam.enable = true;
programs.gamemode.enable = true;

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [

    # Here put libraries that can be shared between apps for non-nix executables

    icu # Required by dotnet in vscode extension
  ];
  # Pipewire sound

  services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # Polkit (needed for GUI elevated prompts)
    security.polkit.enable = true;

    # Portals for Wayland/Hyprland
    xdg.portal.enable = true;
    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];

    # Fonts (nerd + emojis)
    fonts.packages = with pkgs; [
      nerd-fonts.hack
      noto-fonts
      texlivePackages.noto-emoji
      font-awesome
    ];

    # Integrations for Thunar
      programs.xfconf.enable = true;
      services.gvfs.enable = true;
      services.tumbler.enable = true;
      programs.thunar.enable = true;
      programs.thunar.plugins = with pkgs.xfce; [
      thunar-archive-plugin
    ];

    # Enable zsh system level
    programs.zsh.enable = true;
}
