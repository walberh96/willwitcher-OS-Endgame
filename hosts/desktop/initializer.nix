{ config, lib, pkgs, ... }:

let
  normalUserNames =
    lib.attrNames (lib.filterAttrs (_: u: (u.isNormalUser or false)) config.users.users);

  usersList = lib.concatStringsSep " " normalUserNames;
  jqBin = "${pkgs.jq}/bin/jq";
in
{
  system.activationScripts.bootstrapHome = {
    text = ''
      JQ="${jqBin}"
      users="${usersList}"

      ensure_clean_path() {
        target="$1"
        if [ -e "$target" ] || [ -L "$target" ]; then
          rm -rf "$target"
        fi
      }

      # Path where extra .desktop files live in the repo
      src_desktop_dir=${../../hosts/desktop/dotfiles/.desktop_files}

      for user in $users; do
        user_home="$(getent passwd "$user" | cut -d: -f6 || true)"
        if [ -z "$user_home" ]; then
          continue
        fi

        state_file="$user_home/.ww-state.json"

        init_flag="false"
        current_wallpaper=""
        current_gtk_theme=""
        current_cursor=""

        if [ -f "$state_file" ]; then
          current_wallpaper="$($JQ -r '.current_wallpaper // ""' "$state_file" 2>/dev/null || printf '')"
          current_gtk_theme="$($JQ -r '.current_gtk_theme // ""' "$state_file" 2>/dev/null || printf '')"
          current_cursor="$($JQ -r '.current_cursor // ""' "$state_file" 2>/dev/null || printf '')"
          init_raw="$($JQ -r '.if_initialized // "false"' "$state_file" 2>/dev/null || printf 'false')"

          if [ "$init_raw" = "true" ]; then
            init_flag="true"
          fi
        fi

        if [ "$init_flag" = "true" ]; then
          echo "bootstrapHome: $user already initialized (flag true), skipping."
          continue
        fi

        echo "bootstrapHome: seeding dotfiles into $user_home for user $user"

        user_group="$(id -gn "$user" 2>/dev/null || echo "$user")"

        mkdir -p "$user_home"

        # Clean legacy wallpaper marker if present
        ensure_clean_path "$user_home/.wallpaper.current"

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

        # Desktop files: copy ALL .desktop files from .desktop_files/
        mkdir -p "$user_home/.local/share/applications"
        if [ -d "$src_desktop_dir" ]; then
          for f in "$src_desktop_dir"/*.desktop; do
            [ -f "$f" ] || continue
            base="$(basename "$f")"
            target="$user_home/.local/share/applications/$base"
            ensure_clean_path "$target"
            cp "$f" "$target"
          done
        fi

        # Default wallpaper relative path
        # This assumes the repo ships Wallpapers/images/cat.png
        default_wp_rel="images/cat.png"
        if [ ! -f "$user_home/Wallpapers/$default_wp_rel" ]; then
          default_wp_rel=""
        fi

        # Only overwrite current_wallpaper if empty; preserve if it already has a value
        if [ -z "$current_wallpaper" ]; then
          current_wallpaper="$default_wp_rel"
        fi

        if [ -z "$current_gtk_theme" ]; then
          current_gtk_theme=""
        fi

        if [ -z "$current_cursor" ]; then
          current_cursor=""
        fi

        esc() {
          printf '%s' "$1" | sed 's/"/\\"/g'
        }

        cat > "$state_file" <<EOF
{
  "if_initialized": true,
  "current_wallpaper": "$(esc "$current_wallpaper")",
  "current_gtk_theme": "$(esc "$current_gtk_theme")",
  "current_cursor": "$(esc "$current_cursor")"
}
EOF

        chown -R "$user:$user_group" "$user_home"
      done
    '';
  };
}

