{ config, lib, ... }:

let
  # All normal users defined in configuration.nix
  normalUserNames =
    lib.attrNames (lib.filterAttrs (_: u: (u.isNormalUser or false)) config.users.users);

  usersList = lib.concatStringsSep " " normalUserNames;
in
{
  system.activationScripts.bootstrapHome = {
    text = ''
      set -eu

      users="${usersList}"

      # Remove existing path (file/dir/symlink) if present
      ensure_clean_path() {
        target="$1"
        if [ -e "$target" ] || [ -L "$target" ]; then
          rm -rf "$target"
        fi
      }

      # Root directory for user dotfiles in the repo
      dotfiles_root=${../../hosts/desktop/dotfiles}

      for user in $users; do
        user_home="$(getent passwd "$user" | cut -d: -f6 || true)"
        if [ -z "$user_home" ]; then
          continue
        fi

        marker="$user_home/.ww-home-initialized"

        # If this user was already initialized, skip
        if [ -e "$marker" ]; then
          echo "bootstrapHome: $user already initialized, skipping."
          continue
        fi

        echo "bootstrapHome: seeding dotfiles into $user_home for user $user"

        user_group="$(id -gn "$user" 2>/dev/null || echo "$user")"

        mkdir -p "$user_home"

        ########################################################################
        # Wallpapers
        ########################################################################
        ensure_clean_path "$user_home/Wallpapers"
        mkdir -p "$user_home/Wallpapers"
        cp -R ${../../wallpapers}/. "$user_home/Wallpapers"

        ########################################################################
        # .config (all user configs live here)
        ########################################################################
        ensure_clean_path "$user_home/.config"
        mkdir -p "$user_home/.config"
        cp -R "$dotfiles_root/.config/." "$user_home/.config"

        ########################################################################
        # Icons
        ########################################################################
        ensure_clean_path "$user_home/.icons"
        mkdir -p "$user_home/.icons"
        cp -R "$dotfiles_root/.icons/." "$user_home/.icons"

        ensure_clean_path "$user_home/.local/share/icons"
        mkdir -p "$user_home/.local/share/icons"
        cp -R "$dotfiles_root/.icons/." "$user_home/.local/share/icons"

        ########################################################################
        # Fonts
        ########################################################################
        ensure_clean_path "$user_home/.fonts"
        mkdir -p "$user_home/.fonts"
        cp -R "$dotfiles_root/.fonts/." "$user_home/.fonts"

        ensure_clean_path "$user_home/.local/share/fonts"
        mkdir -p "$user_home/.local/share/fonts"
        cp -R "$dotfiles_root/.fonts/." "$user_home/.local/share/fonts"

        ########################################################################
        # Themes
        ########################################################################
        ensure_clean_path "$user_home/.themes"
        mkdir -p "$user_home/.themes"
        cp -R "$dotfiles_root/.themes/." "$user_home/.themes"

        ########################################################################
        # Scripts (~/.local/bin)
        ########################################################################
        ensure_clean_path "$user_home/.local/bin"
        mkdir -p "$user_home/.local/bin"
        cp -R ${../../scripts}/. "$user_home/.local/bin"

        ########################################################################
        # Zsh configuration
        ########################################################################
        ensure_clean_path "$user_home/.zshrc"
        cp "$dotfiles_root/.zshrc" "$user_home/.zshrc"

        ensure_clean_path "$user_home/.zsh"
        mkdir -p "$user_home/.zsh"
        cp -R "$dotfiles_root/.zsh/." "$user_home/.zsh"

        ########################################################################
        # .desktop files (all launchers from dotfiles_root/.desktop_files)
        ########################################################################
        mkdir -p "$user_home/.local/share/applications"
        src_desktop_dir="$dotfiles_root/.desktop_files"

        if [ -d "$src_desktop_dir" ]; then
          for f in "$src_desktop_dir"/*.desktop; do
            [ -f "$f" ] || continue
            base="$(basename "$f")"
            target="$user_home/.local/share/applications/$base"
            ensure_clean_path "$target"
            cp "$f" "$target"
          done
        fi

        ########################################################################
        # Final ownership (only what we manage) + marker
        ########################################################################

        paths_to_chown="
$user_home/Wallpapers
$user_home/.config
$user_home/.icons
$user_home/.local/share/icons
$user_home/.fonts
$user_home/.local/share/fonts
$user_home/.themes
$user_home/.local/bin
$user_home/.zshrc
$user_home/.zsh
$user_home/.local/share/applications
$marker
"

        # Create marker now so we can chown it too
        touch "$marker" || true

        for p in $paths_to_chown; do
          if [ -e "$p" ] || [ -L "$p" ]; then
            chown -R "$user:$user_group" "$p" || true
          fi
        done
      done
    '';
  };
}

