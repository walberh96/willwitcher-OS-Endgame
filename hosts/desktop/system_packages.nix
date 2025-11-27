# ALL SYSTEM-WIDE PACKAGES (ALL USERS)
{ pkgs }:
with pkgs; [

#-----------------------------------------------------

qmk   # QMK CLI for building/flashing
via   # native VIA app (optional but nice to have)
git
ntfs3g
udiskie
p7zip
unar
xz
zstd
bzip3
gzip
gnutar
libarchive
zoxide
ripgrep
fd
fzf
jq
lsd
bat
pass
gnupg
libnotify
slurp
# Media and low-level tools
ffmpeg
v4l-utils
procps
gawk
gnugrep
papirus-icon-theme
gnused
stow

#------------------------------------------------------
]
