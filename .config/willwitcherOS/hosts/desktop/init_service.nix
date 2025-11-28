{ config, pkgs, ... }:

let
  # Shell application that bootstraps and syncs dotfiles using GNU stow
  wwDotfilesSync = pkgs.writeShellApplication {
    name = "ww-dotfiles-sync";

    # Binaries required by the script at runtime
    runtimeInputs = [
      pkgs.git
      pkgs.stow
      pkgs.coreutils
      pkgs.gnused
      pkgs.gnugrep
    ];

    text = ''
      set -euo pipefail

      # Dotfiles repository (override with DOTFILES_REPO if needed)
      DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/walberh96/willwitcher-OS-Endgame.git}"
      DOTFILES_DIR="${HOME}/dotfiles"

      # Marker in $HOME (can be made root-owned manually with sudo)
      MARKER_FILE="${HOME}/.ww_initialized_flag"

      echo "ww-dotfiles-sync: starting..."

      ####################################################################
      # Clone / update logic with marker
      ####################################################################
      if [ ! -d "$DOTFILES_DIR" ]; then
        echo "ww-dotfiles-sync: '${DOTFILES_DIR}' does not exist, cloning from repo (shallow)..."
        git clone --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR"
      else
        if [ ! -f "$MARKER_FILE" ]; then
          echo "ww-dotfiles-sync: marker file not found, updating existing repo from remote..."
          # Determine current branch
          branch="$(git -C "$DOTFILES_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"

          git -C "$DOTFILES_DIR" fetch --all --tags \
            || echo "ww-dotfiles-sync: git fetch failed, continuing with local state"

          git -C "$DOTFILES_DIR" pull --ff-only origin "$branch" \
            || echo "ww-dotfiles-sync: git pull failed (non-fast-forward or offline), continuing with local state"
        else
          echo "ww-dotfiles-sync: marker file present, skipping git fetch/pull."
        fi
      fi

      cd "$DOTFILES_DIR"

      ####################################################################
      # Apply stow packages (aggressive, your repo wins)
      ####################################################################
      echo "ww-dotfiles-sync: applying stow packages..."
      for dir in */; do
        [ -d "$dir" ] || continue
        case "$dir" in
          .git/ ) continue ;;
        esac

        pkg="${dir%/}"

        # Special handling for Hyprland: remove default config completely
        if [ "$pkg" = "hypr" ]; then
          echo "  -> cleaning existing Hyprland config at ${HOME}/.config/hypr"
          rm -rf "${HOME}/.config/hypr"
        fi

        echo "  -> checking conflicts for package '$pkg' (dry-run)..."
        # Dry-run to detect conflicts; do not abort on non-zero here
        conflicts="$(stow -n -v -t "$HOME" "$pkg" 2>&1 || true)"

        # Show dry-run output (useful when inspecting logs)
        echo "$conflicts"

        # Remove any paths that stow marks as CONFLICT
        if printf '%s\n' "$conflicts" | grep -q '^CONFLICT:'; then
          echo "    conflicts found, removing conflicting paths..."
          printf '%s\n' "$conflicts" | while IFS= read -r line; do
            case "$line" in
              CONFLICT:\ *)
                # Example line:
                # CONFLICT: .config/hypr/hyprland.conf already exists but is not a symlink
                rel="${line#CONFLICT: }"
                rel="${rel%% already exists*}"
                rel="$(printf '%s' "$rel" | sed 's/^[[:space:]]*//')"

                if [ -n "$rel" ]; then
                  target="${HOME}/${rel}"
                  echo "      -> removing '${target}'"
                  rm -rf -- "$target"
                fi
                ;;
            esac
          done
        else
          echo "    no conflicts for package '$pkg'."
        fi

        echo "  -> stow $pkg"
        stow -R -t "$HOME" "$pkg"
      done

      ####################################################################
      # Mark initialization / update done
      ####################################################################
      touch "$MARKER_FILE"

      ####################################################################
      # Reload Hyprland config
      ####################################################################
      echo "ww-dotfiles-sync: reloading Hyprland config..."
      if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload || echo "ww-dotfiles-sync: hyprctl reload failed (is Hyprland running?)"
      else
        echo "ww-dotfiles-sync: hyprctl not found, cannot reload Hyprland."
      fi

      echo "ww-dotfiles-sync: done."
    '';
  };
in
{
  ############################
  # Expose script in PATH
  ############################
  environment.systemPackages = [
    wwDotfilesSync
  ];

  ############################
  # Systemd user service
  ############################
  systemd.user.services."ww-dotfiles-sync" = {
    Unit = {
      Description = "Sync dotfiles with GNU stow at login";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${wwDotfilesSync}/bin/ww-dotfiles-sync";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}

