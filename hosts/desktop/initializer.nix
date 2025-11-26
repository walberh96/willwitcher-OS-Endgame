{ config, lib, ... }:

let
  normalUserNames =
    lib.attrNames (lib.filterAttrs (_: u: (u.isNormalUser or false)) config.users.users);

  usersList = lib.concatStringsSep " " normalUserNames;
in
{
  system.activationScripts.bootstrapHome = {
    text = ''
      users="${usersList}"

      DEFAULT_GTK_THEME="Catppuccin-BL-LB-Dark"
      DEFAULT_CURSOR="catppuccin-mocha-dark-cursors"

      ensure_clean_path() {
        target="$1"
        if [ -e "$target" ] || [ -L "$target" ]; then
          rm -rf "$target"
        fi
      }

      # Simple helper: we do NOT support double quotes in these values
      esc() {
        case "$1" in
          *\"*)
            echo "bootstrapHome: value contains double quotes, which are not supported: $1" >&2
            # Print value as-is anyway; all your current values do not use quotes
            ;;
        esac
        printf '%s' "$1"
      }

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

        # Read existing state if present
        if [ -f "$state_file" ]; then
          if command -v jq >/dev/null 2>&1; then
            current_wallpaper="$(jq -r '.current_wallpaper // ""' "$state_file" 2>/dev/null)"
            current_gtk_theme="$(jq -r '.current_gtk_theme // ""' "$state_file" 2>/dev/null)"
            current_cursor="$(jq -r '.current_cursor // ""' "$state_file" 2>/dev/null)"
            init_raw="$(jq -r '.if_initialized // false' "$state_file" 2>/dev/null)"

            if [ "$init_raw" = "true" ]; then
              init_flag="true"
            fi
          else
            # State exists but jq is missing → assume initialized to avoid corrupting unknown content
            init_flag="true"
          fi
        fi

        if [ "$init_flag" = "true" ]; then
          echo "bootstrapHome: $user already initialized, skipping."
          continue
        fi

        echo "bootstrapHome: seeding dotfiles into $user_home for user $user"

        user_group="$(id -gn "$user" 2>/dev/null || echo "$user")"

        mkdir -p "$user_home"

        # Clean legacy markers / symlinks from previous setups
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

        # Desktop files: copy all .desktop files from .desktop_files/
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

        # Default wallpaper relative path: Wallpapers/images/cat.png
        default_wp_rel="images/cat.png"
        if [ ! -f "$user_home/Wallpapers/$default_wp_rel" ]; then
          default_wp_rel=""
        fi

        # Fill defaults only when empty (to preserve custom values on reseed)
        if [ -z "$current_wallpaper" ]; then
          current_wallpaper="$default_wp_rel"
        fi

        if [ -z "$current_gtk_theme" ]; then
          current_gtk_theme="$DEFAULT_GTK_THEME"
        fi

        if [ -z "$current_cursor" ]; then
          current_cursor="$DEFAULT_CURSOR"
        fi

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

