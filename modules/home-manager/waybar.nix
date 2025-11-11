{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkForce;
  # Stylix palette with '#' prefixed colors
  c = config.lib.stylix.colors.withHashtag;

  # Wrapper: ww-srec (usa gpu-screen-recorder; soporta status JSON para Waybar)
  srec = pkgs.writeShellScriptBin "ww-srec" ''
    #!/usr/bin/env bash
    set -euo pipefail
    # Debug opcional: WW_SREC_DEBUG=1 ww-srec ...
    [[ -n "''${WW_SREC_DEBUG:-}" ]] && set -x

    HYPRCTL="${pkgs.hyprland}/bin/hyprctl"
    JQ="${pkgs.jq}/bin/jq"
    SLURP="${pkgs.slurp}/bin/slurp"
    GSR="${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder"
    FFPLAY="${pkgs.ffmpeg-full}/bin/ffplay"
    V4L2CTL="${pkgs.v4l-utils}/bin/v4l2-ctl"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    PKILL="${pkgs.procps}/bin/pkill"
    PGREP="${pkgs.procps}/bin/pgrep"
    AWK="${pkgs.gawk}/bin/awk"
    DATE="${pkgs.coreutils}/bin/date"
    GREP="${pkgs.gnugrep}/bin/grep"
    XDG_OPEN="${pkgs.xdg-utils}/bin/xdg-open"

    [[ -f "''${HOME}/.config/user-dirs.dirs" ]] && source "''${HOME}/.config/user-dirs.dirs"
    OUTPUT_DIR="''${OMARCHY_SCREENRECORD_DIR:-''${XDG_VIDEOS_DIR:-$HOME/Videos}}"

    RUNTIME="''${XDG_RUNTIME_DIR:-/tmp}"
    STARTFILE="''${RUNTIME}/ww-srec.start"
    LASTFILE="''${RUNTIME}/ww-srec-lastfile"

    SCOPE=""
    AUDIO="false"
    WEBCAM="false"

    # Parse flags temprano, dejando $1 libre para subcomandos (status/open)
    for arg in "$@"; do
      case "''${arg}" in
        --with-audio) AUDIO="true" ;;
        --with-webcam) WEBCAM="true" ;;
        output|region) SCOPE="''${arg}" ;;
      esac
    done

    cleanup_webcam() {
      "''${PKILL}" -f "WebcamOverlay" 2>/dev/null || true
    }

    start_webcam_overlay() {
      cleanup_webcam

      local scale="$("''${HYPRCTL}" monitors -j | "''${JQ}" -r 'map(select(.focused==true))[0].scale')"
      [[ -z "''${scale}" ]] && scale=1

      local target_width=$("''${AWK}" "BEGIN {printf \"%.0f\", 360 * ''${scale}}")

      local preferred_resolutions=("640x360" "1280x720" "1920x1080")
      local video_size_arg=""
      local available_formats=$("''${V4L2CTL}" --list-formats-ext -d /dev/video0 2>/dev/null || true)

      for resolution in "''${preferred_resolutions[@]}"; do
        if echo "''${available_formats}" | "''${GREP}" -q "''${resolution}"; then
          video_size_arg="-video_size ''${resolution}"
          break
        fi
      done

      "''${FFPLAY}" -f v4l2 ''${video_size_arg} -framerate 30 /dev/video0 \
        -vf "scale=''${target_width}:-1" \
        -window_title "WebcamOverlay" \
        -noborder \
        -fflags nobuffer -flags low_delay \
        -probesize 32 -analyzeduration 0 \
        -loglevel quiet >/dev/null 2>&1 &
      sleep 1
    }

    toggle_screenrecording_indicator() {
      "''${PKILL}" -RTMIN+8 waybar || true
    }

    status_json() {
      if "''${PGREP}" -f "gpu-screen-recorder" >/dev/null; then
        local start now elapsed mm ss file tip
        start=$(cat "''${STARTFILE}" 2>/dev/null || echo 0)
        now=$("''${DATE}" +%s)
        elapsed=$(( now - start ))
        (( elapsed < 0 )) && elapsed=0
        mm=$(( elapsed / 60 ))
        ss=$(( elapsed % 60 ))
        file=$(cat "''${LASTFILE}" 2>/dev/null || echo "")
        tip="Recording → ''${mm}:$(printf "%02d" "''${ss}")"
        [[ -n "''${file}" ]] && tip="''${tip}\n''${file}"
        printf '{"text":"REC %d:%02d","alt":"rec","class":"recording","tooltip":"%s"}\n' "''${mm}" "''${ss}" "''${tip}"
      elif "''${PGREP}" -x slurp >/dev/null; then
        printf '{"text":"Selecting","alt":"idle","class":"idle","tooltip":"Selecting region… (Esc to cancel)"}\n'
      elif "''${PGREP}" -f "WebcamOverlay" >/dev/null; then
        printf '{"text":"Webcam","alt":"idle","class":"idle","tooltip":"Webcam overlay active"}\n'
      else
        printf '{"text":"Idle","alt":"idle","class":"idle","tooltip":"Click: Output (audio) · Middle: Region (audio) · Right: Open Folder"}\n'
      fi
    }

    open_dir() {
      if [[ -d "''${OUTPUT_DIR}" ]]; then
        "''${XDG_OPEN}" "''${OUTPUT_DIR}" >/dev/null 2>&1 &
      else
        "''${NOTIFY}" "Screen recording directory does not exist: ''${OUTPUT_DIR}" -u critical -t 3000
        exit 1
      fi
    }

    start_screenrecording() {
      if [[ ! -d "''${OUTPUT_DIR}" ]]; then
        "''${NOTIFY}" "Screen recording directory does not exist: ''${OUTPUT_DIR}" -u critical -t 3000
        exit 1
      fi

      local filename="''${OUTPUT_DIR}/screenrecording-$("''${DATE}" +'%Y-%m-%d_%H-%M-%S').mp4"
      local audio_args=""
      [[ "''${AUDIO}" == "true" ]] && audio_args="-a default_output|default_input"

      nohup "''${GSR}" -w "$@" -f 60 -c mp4 -o "''${filename}" ''${audio_args} >/dev/null 2>&1 &
      "''${DATE}" +%s > "''${STARTFILE}"
      echo "''${filename}" > "''${LASTFILE}"
      toggle_screenrecording_indicator
    }

    stop_screenrecording() {
      "''${PKILL}" -SIGINT -f "gpu-screen-recorder" 2>/dev/null || true

      local count=0
      while "''${PGREP}" -f "gpu-screen-recorder" >/dev/null && [ "''${count}" -lt 50 ]; do
        sleep 0.1
        count=$((count + 1))
      done

      if "''${PGREP}" -f "gpu-screen-recorder" >/dev/null; then
        "''${PKILL}" -9 -f "gpu-screen-recorder" 2>/dev/null || true
        cleanup_webcam
        "''${NOTIFY}" "Screen recording error" "Recording process had to be force-killed. Video may be corrupted." -u critical -t 5000
      else
        cleanup_webcam
        "''${NOTIFY}" "Screen recording saved to ''${OUTPUT_DIR}" -t 2000
      fi
      toggle_screenrecording_indicator
    }

    screenrecording_active() {
      "''${PGREP}" -f "gpu-screen-recorder" >/dev/null || "''${PGREP}" -x slurp >/dev/null || "''${PGREP}" -f "WebcamOverlay" >/dev/null
    }

    # Subcomandos especiales para Waybar
    if [[ "''${1:-}" == "status" ]]; then
      status_json
      exit 0
    elif [[ "''${1:-}" == "open" ]]; then
      open_dir
      exit 0
    fi

    # Flujo principal (toggle según estado actual)
    if screenrecording_active; then
      if "''${PGREP}" -x slurp >/dev/null; then
        "''${PKILL}" -x slurp 2>/dev/null || true
      elif "''${PGREP}" -f "WebcamOverlay" >/dev/null && ! "''${PGREP}" -f "gpu-screen-recorder" >/dev/null; then
        cleanup_webcam
      else
        stop_screenrecording
      fi
      exit 0
    fi

    # Iniciar según scope
    if [[ "''${SCOPE}" == "output" ]]; then
      [[ "''${WEBCAM}" == "true" ]] && start_webcam_overlay

      # Monitor enfocado (sin slurp); fallback a slurp -o si no hay focused
      output=$("''${HYPRCTL}" monitors -j | "''${JQ}" -r 'map(select(.focused==true))[0].name // empty')
      if [[ -z "''${output}" ]]; then
        if ! output=$("''${SLURP}" -o -f "%o"); then
          [[ "''${WEBCAM}" == "true" ]] && cleanup_webcam
          exit 1
        fi
      fi

      start_screenrecording "''${output}"
    else
      [[ "''${WEBCAM}" == "true" ]] && start_webcam_overlay

      scale=$("''${HYPRCTL}" monitors -j | "''${JQ}" -r '.[] | select(.focused == true) | .scale')
      [[ -z "''${scale}" ]] && scale=1

      if ! region=$("''${SLURP}" -f "%wx%h+%x+%y"); then
        [[ "''${WEBCAM}" == "true" ]] && cleanup_webcam
        exit 1
      fi

      if [[ "''${region}" =~ ^([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)$ ]]; then
        w=$("''${AWK}" "BEGIN {printf \"%.0f\", ''${BASH_REMATCH[1]} * ''${scale}}")
        h=$("''${AWK}" "BEGIN {printf \"%.0f\", ''${BASH_REMATCH[2]} * ''${scale}}")
        x=$("''${AWK}" "BEGIN {printf \"%.0f\", ''${BASH_REMATCH[3]} * ''${scale}}")
        y=$("''${AWK}" "BEGIN {printf \"%.0f\", ''${BASH_REMATCH[4]} * ''${scale}}")
        scaled_region="''${w}x''${h}+''${x}+''${y}"
      else
        scaled_region="''${region}"
      fi

      start_screenrecording region -region "''${scaled_region}"
    fi
  '';
in
{
  ##############################################################################
  # OPTION
  ##############################################################################
  options.willwitcher.waybar.enable =
    mkEnableOption "Enable WillWitcher Waybar config (Stylix owns palette)";

  ##############################################################################
  # CONFIG
  ##############################################################################
  config = mkIf config.willwitcher.waybar.enable {
    # Stylix: theme Waybar but do not inject custom CSS via Stylix
    stylix.targets.waybar = {
      enable = true;
      addCss = false;
    };

    # Paquetes requeridos por ww-srec y Waybar custom module
    home.packages = [
      srec
      pkgs.slurp
      pkgs.hyprland      # hyprctl
      pkgs.jq
      pkgs.gpu-screen-recorder
      pkgs.ffmpeg-full   # ffplay
      pkgs.v4l-utils     # v4l2-ctl
      pkgs.libnotify     # notify-send
      pkgs.xdg-utils     # xdg-open
      pkgs.procps        # pgrep/pkill
      pkgs.gnugrep       # grep
      pkgs.gawk          # awk
    ];

    programs.waybar = {
      enable = true;

      # CSS (usa Stylix)
      style = mkForce ''
        * { font-size: 16px; } /* font-family handled by Stylix */
        window#waybar { background-color: transparent; }

        #workspaces {
          background: ${c.base00}; color: ${c.base05};
          border-radius: 15px; margin-top: 10px; margin-right: 10px; margin-left: 5px;
          padding: 4px; border: 1px solid ${c.base02};
        }
        #workspaces button {
          background: transparent; color: ${c.base0E};
          border-radius: 10px; margin: 0 3px; padding: 4px 10px;
          font-weight: 600; box-shadow: none;
        }
        #workspaces button.active { background-color: ${c.base01}; color: ${c.base0D}; }
        #workspaces button:not(.active):not(.empty) { background-color: ${c.base00}; color: ${c.base0B}; }

        #clock, #tray, #custom-notification, #pulseaudio, #custom-power, #custom-wlrec {
          background: ${c.base00}; color: ${c.base0E};
          border: 1px solid ${c.base02}; border-radius: 15px;
          margin-right: 10px; margin-top: 10px; padding: 4px 16px; font-weight: 700;
        }
        #clock { font-size: 20px; padding-top: 4px; padding-bottom: 2px; }
        #custom-power:hover { color: ${c.base08}; }

        /* Recorder states */
        #custom-wlrec.recording { color: ${c.base08}; border-color: ${c.base08}; }
        #custom-wlrec.idle      { color: ${c.base0E}; }
      '';

      settings = [
        {
          layer = "top";
          position = "top";
          height = 50;
          spacing = 5;
          "margin-bottom" = -5;

          "modules-left"   = [ "hyprland/workspaces" ];
          "modules-center" = [ "clock" ];
          "modules-right"  = [ "custom/wlrec" "custom/notification" "pulseaudio" "tray" "custom/power" ];

          # Workspaces (persistentes por monitor)
          "hyprland/workspaces" = {
            "on-scroll-up" = "hyprctl dispatch workspace r-1";
            "on-scroll-down" = "hyprctl dispatch workspace r+1";
            "on-click" = "activate";
            "active-only" = false;
            "all-outputs" = true;
            format = "{}";
            "format-icons" = { urgent = ""; active = ""; default = ""; };
            "persistent-workspaces" = { "*" = 5; };
          };

          "clock" = { "format-alt" = "{:%Y-%m-%d}"; tooltip = false; };

          "tray"  = { "icon-size" = 20; spacing = 13; };

          "custom/notification" = {
            tooltip = false;
            format = " {icon} ";
            "format-icons" = {
              notification             = ''<span foreground="red"><sup></sup></span>'';
              none                     = "";
              "dnd-notification"       = ''<span foreground="red"><sup></sup></span>'';
              "dnd-none"               = "";
              "inhibited-notification" = ''<span foreground="red"><sup></sup></span>'';
              "inhibited-none"         = "";
              "dnd-inhibited-notification" = ''<span foreground="red"><sup></sup></span>'';
              "dnd-inhibited-none"         = "";
            };
            "return-type" = "json";
            "exec-if" = "which swaync-client";
            exec = "swaync-client -swb";
            "on-click" = "swaync-client -t -sw";
            "on-click-right" = "swaync-client -d -sw";
            escape = true;
          };

          "pulseaudio" = {
            format = "{volume}% {icon}";
            "format-icons" = { default = [ "" "" "" ]; };
            "on-click" = "pwvucontrol";
          };

          # ====== Módulo que usa ww-srec ======
          "custom/wlrec" = {
            "return-type" = "json";
            "format" = " {icon} {text} ";
            "format-icons" = { "idle" = "⏺"; "rec" = "⏹"; };
            "exec-if" = "command -v ww-srec";
            exec = "ww-srec status";
            interval = 1;
            signal = 8;
            tooltip = true;

            # Clicks: Output / Region / Open folder (si ya está grabando, hace stop)
            "on-click" = "ww-srec output --with-audio";
            "on-click-middle" = "ww-srec region --with-audio";
            "on-click-right" = "ww-srec open";

            "escape" = true;
          };

          "custom/power" = {
            format = " ⏻ ";
            tooltip = "Power menu";
            "on-click" = "wlogout";
            "return-type" = "string";
          };
        }
      ];
    };
  };
}

