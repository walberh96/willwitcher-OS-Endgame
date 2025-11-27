# ALL USER PACKAGES (SINGLE USER CONFIG)
{ pkgs }:
with pkgs; [
# Desktop applications
  signal-desktop
  mpv
  zathura
  qimgv
  libreoffice

  # Hyprland / Wayland related tools
  hyprpaper
  hyprlock
  hyprpicker
  hyprshot
  wl-clipboard
  swaynotificationcenter
  waybar
  blueman
  mpvpaper
  xarchiver
  cliphist

  # Documents and typesetting
  pandoc
  texliveTeTeX

  # Extended search / utilities
  ripgrep-all
  gh
  nb
  fastfetch

  # Gaming and GPU tools
  gpu-screen-recorder-gtk
  gpu-screen-recorder
  lutris

  # Rust toolchain and build essentials
  rustc
  cargo
  rustfmt
  clippy
  rust-analyzer
  lldb
  gcc
  binutils
  pkg-config

  # Audio control
  pwvucontrol

  # AI client
  gemini-cli

  # LSP / formatting / scripting tooling
  marksman
  deno

  # TUI / desktop apps
  wlogout
  yazi
  rofi
  wezterm
  neovim
  swww
  vesktop
  firefox
  networkmanagerapplet
  ripdrag
  btop
  headsetcontrol
  brave
  gnused
  nwg-look
  waypaper
]
