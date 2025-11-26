{ config, lib, ... }:

let
  normalUserNames =
    lib.attrNames (lib.filterAttrs (_: u: (u.isNormalUser or false)) config.users.users);

  usersList = lib.concatStringsSep " " normalUserNames;
in
{
  # One-time home bootstrap (dotfiles, assets, scripts) for all normal users
  system.activationScripts.bootstrapHome = {
    text = ''
      users="${usersList}"

      ensure_clean_path() {
        target="$1"
        if [ -e "$target" ] || [ -L "$target" ]; then
          rm -rf "$target"
        fi
      }

      for user in $users; do
        user_home="$(getent passwd "$user" | cut -d: -f6 || true)"
        if [ -z "$user_home" ]; then
          continue
        fi

        marker="$user_home/.ww-home-initialized"

        if [ -e "$marker" ]; then
          echo "bootstrapHome: $user already initialized, skipping."
          continue
        fi

        echo "bootstrapHome: seeding dotfiles into $user_home for user $user"

        user_group="$(id -gn "$user" 2>/dev/null || echo "$user")"

        mkdir -p "$user_home"

        # Wallpapers
        ensure_clean_path "$user_home/Wallpapers"
        mkdir -p "$user_home/Wallpapers"
        cp -R ${../../wallpapers}/. "$user_home/Wallpapers"

        # Configuration directory
        ensure_clean_path "$user_home/.config"
        mkdir -p "$user_home/.config"
        cp -R ${../../hosts/desktop/dotfiles/.config}/. "$user_home/.config"

        # Icons
        ensure_clean_path "$user_home/.icons"
        mkdir -p "$user_home/.icons"
        cp -R ${../../hosts/desktop/dotfiles/.icons}/. "$user_home/.icons"

        ensure_clean_path "$user_home/.local/share/icons"
        mkdir -p "$user_home/.local/share/icons"
        cp -R ${../../hosts/desktop/dotfiles/.icons}/. "$user_home/.local/share/icons"

        # Fonts
        ensure_clean_path "$user_home/.fonts"
        mkdir -p "$user_home/.fonts"
        cp -R ${../../hosts/desktop/dotfiles/.fonts}/. "$user_home/.fonts"

        ensure_clean_path "$user_home/.local/share/fonts"
        mkdir -p "$user_home/.local/share/fonts"
        cp -R ${../../hosts/desktop/dotfiles/.fonts}/. "$user_home/.local/share/fonts"

        # Themes
        ensure_clean_path "$user_home/.themes"
        mkdir -p "$user_home/.themes"
        cp -R ${../../hosts/desktop/dotfiles/.themes}/. "$user_home/.themes"

        # Scripts
        ensure_clean_path "$user_home/.local/bin"
        mkdir -p "$user_home/.local/bin"
        cp -R ${../../scripts}/. "$user_home/.local/bin"

        # Mozilla profile
        ensure_clean_path "$user_home/.mozilla"
        mkdir -p "$user_home/.mozilla"
        cp -R ${../../hosts/desktop/dotfiles/.mozilla}/. "$user_home/.mozilla"

        # Zsh configuration
        ensure_clean_path "$user_home/.zshrc"
        cp ${../../hosts/desktop/dotfiles/.zshrc} "$user_home/.zshrc"

        ensure_clean_path "$user_home/.zsh"
        mkdir -p "$user_home/.zsh"
        cp -R ${../../hosts/desktop/dotfiles/.zsh}/. "$user_home/.zsh"

        # Desktop file
        ensure_clean_path "$user_home/.local/share/applications/ww-wallpaper-picker.desktop"
        mkdir -p "$user_home/.local/share/applications"
        cp ${../../hosts/desktop/dotfiles/.desktop_files/ww-wallpaper-picker.desktop} \
          "$user_home/.local/share/applications/ww-wallpaper-picker.desktop"

        chown -R "$user:$user_group" "$user_home"

        touch "$marker"
      done
    '';
  };

  # Ensure a default wallpaper pointer exists for all normal users
  system.activationScripts.initWallpaperCurrent = {
    text = ''
      users="${usersList}"

      for user in $users; do
        user_home="$(getent passwd "$user" | cut -d: -f6 || true)"
        if [ -z "$user_home" ]; then
          continue
        fi

        user_group="$(id -gn "$user" 2>/dev/null || echo "$user")"
        current="$user_home/.wallpaper.current"

        if [ ! -f "$current" ]; then
          mkdir -p "$user_home"
          cp ${../../hosts/desktop/dotfiles/.wallpaper.default} "$current"
          chown "$user:$user_group" "$current"
        fi
      done
    '';
  };
}

