{ config, pkgs, inputs, lib, ... }:

{
  ################################################################################
  # NixOS (system scope)
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

  # XKB layout for Xwayland/X11 clients
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  #####################################
  ## Stylix (sistema)
  #####################################
  stylix = {
    enable = true;
    autoEnable = true;
    image = ./wallpapers/kenpachi.png;

    # Si usas esquemas base16 propios, deja la ruta que ya tenías:
    base16Scheme = ../../themes/catppuccin-mocha.yaml;
    targets.regreet.useWallpaper = false;
    # Fuentes globales
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

    # 👇 Cursor a nivel sistema (para que también aplique en la pantalla de login)
    cursor = {
      package = pkgs.bibata-cursors;
      name    = "Bibata-Modern-Ice";
      size    = 24;
    };
  };

  #####################################
  ## Users
  #####################################
  users.users.willwitcher = {
    isNormalUser = true;
    description  = "willwitcher";
    extraGroups  = [ "networkmanager" "wheel" ];
    shell        = pkgs.zsh;
  };
  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  #####################################
  ## Display manager + Hyprland compositor
  #####################################
  # ReGreet (Wayland) lanzado en cage, heredando dark/light y cursor desde Stylix
  services.greetd.enable = true;

  # Helpers para leer de Stylix (con fallback)
  # preferDark: "dark"|"light"; cursorName/Size desde config.stylix.cursor
  # NOTA: si cambias estos valores en Stylix, el login reflejará el cambio en el próximo rebuild.
  services.greetd.settings = let
    preferDark =
      if lib.hasAttrByPath [ "stylix" "polarity" ] config
      then config.stylix.polarity else "dark";
    cursorName =
      if lib.hasAttrByPath [ "stylix" "cursor" "name" ] config
      then config.stylix.cursor.name else "default";
    cursorSize =
      if lib.hasAttrByPath [ "stylix" "cursor" "size" ] config
      then toString config.stylix.cursor.size else "24";
  in {
    default_session = {
      user = "greeter";
      command = ''
        XCURSOR_THEME='${cursorName}' \
        XCURSOR_SIZE='${cursorSize}' \
        GTK_APPLICATION_PREFER_DARK_THEME='${if preferDark == "dark" then "1" else "0"}' \
        ${pkgs.cage}/bin/cage -s -mlast -- ${pkgs.regreet}/bin/regreet
      '';
    };
  };

  programs.regreet.enable = true;
  # Haz que ReGreet use TU archivo TOML del repo (resuelve el conflicto)
  programs.regreet.settings = lib.mkForce (
    inputs.self + /nixos/configs/loginManager/regreet.toml
  );
  # Toma tu config del repo (carpeta "config/") y publícala en /etc

  environment.etc."greetd/wallpapers/login.jpg".source =
    inputs.self + /nixos/configs/loginManager/login.jpg;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  #####################################
  ## Audio (PipeWire)
  #####################################
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
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

  #####################################
  ## Thunar + previews
  #####################################
  programs.xfconf.enable = true;
  services.gvfs.enable   = true;
  services.tumbler.enable = true;
  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs.xfce; [ thunar-archive-plugin ];

  #####################################
  ## Gaming
  #####################################
  hardware.steam-hardware.enable = true;
  programs.steam.enable = true;
  programs.gamemode.enable = true;

  #####################################
  ## nix-ld
  #####################################
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ icu ];

  #####################################
  ## System packages
  #####################################
  environment.systemPackages = with pkgs; [
    # opcional: cage ya se invoca por ruta absoluta, así que no es imprescindible
  ];

  #####################################
  ## Nix settings
  #####################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  #####################################
  ## Home Manager wiring
  #####################################
  home-manager = {
    useGlobalPkgs   = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "hm-bak";
    users.willwitcher = import ./home.nix;
  };

  system.stateVersion = "25.05";
}
