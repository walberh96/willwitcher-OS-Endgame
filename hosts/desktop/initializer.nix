{ ... }:

{
  # One-time home bootstrap (dotfiles, assets, scripts)
  system.activationScripts.bootstrapHome = {
    text = ''
      user_home="/home/willwitcher"
      marker="$user_home/.ww-home-initialized"

      if [ -e "$marker" ]; then
        echo "bootstrapHome: already initialized, skipping."
        exit 0
      fi

      echo "bootstrapHome: seeding dotfiles into $user_home"

      mkdir -p "$user_home"

      # Wallpapers
      mkdir -p "$user_home/Wallpapers"
      cp -R ${../../wallpapers}/. "$user_home/Wallpapers"

      # Configuration directory
      mkdir -p "$user_home/.config"
      cp -R ${../../hosts/desktop/dotfiles/.config}/. "$user_home/.config"

      # Icons
      mkdir -p "$user_home/.icons"
      cp -R ${../../hosts/desktop/dotfiles/.icons}/. "$user_home/.icons"
      mkdir -p "$user_home/.local/share/icons"
      cp -R ${../../hosts/desktop/dotfiles/.icons}/. "$user_home/.local/share/icons"

      # Fonts
      mkdir -p "$user_home/.fonts"
      cp -R ${../../hosts/desktop/dotfiles/.fonts}/. "$user_home/.fonts"
      mkdir -p "$user_home/.local/share/fonts"
      cp -R ${../../hosts/desktop/dotfiles/.fonts}/. "$user_home/.local/share/fonts"

      # Themes
      mkdir -p "$user_home/.themes"
      cp -R ${../../hosts/desktop/dotfiles/.themes}/. "$user_home/.themes"

      # Scripts
      mkdir -p "$user_home/.local/bin"
      cp -R ${../../scripts}/. "$user_home/.local/bin"

      # Mozilla profile
      mkdir -p "$user_home/.mozilla"
      cp -R ${../../hosts/desktop/dotfiles/.mozilla}/. "$user_home/.mozilla"

      # Zsh configuration
      cp ${../../hosts/desktop/dotfiles/.zshrc} "$user_home/.zshrc"
      mkdir -p "$user_home/.zsh"
      cp -R ${../../hosts/desktop/dotfiles/.zsh}/. "$user_home/.zsh"

      # Desktop file
      mkdir -p "$user_home/.local/share/applications"
      cp ${../../hosts/desktop/dotfiles/.desktop_files/ww-wallpaper-picker.desktop} \
        "$user_home/.local/share/applications/ww-wallpaper-picker.desktop"

      chown -R willwitcher:users "$user_home"

      touch "$marker"
    '';
  };

  # Ensure a default wallpaper pointer exists
  system.activationScripts.initWallpaperCurrent = {
    text = ''
      user_home="/home/willwitcher"
      current="$user_home/.wallpaper.current"

      if [ ! -f "$current" ]; then
        cp ${../../hosts/desktop/dotfiles/.wallpaper.default} "$current"
        chown willwitcher:users "$current"
      fi
    '';
  };
}

