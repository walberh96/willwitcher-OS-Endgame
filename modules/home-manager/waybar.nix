{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkForce;
  # Paleta de Stylix con '#'
  c = config.lib.stylix.colors.withHashtag;

  # Wrapper: ww-wlrec (toggle, start/stop, región con slurp, status JSON para Waybar)
  wlrec = pkgs.writeShellScriptBin "ww-wlrec" ''
    #!/usr/bin/env bash
    set -euo pipefail

    WLS="${pkgs.wl-screenrec}/bin/wl-screenrec"
    HYPR="${pkgs.hyprland}/bin/hyprctl"
    JQ="${pkgs.jq}/bin/jq"
    SLURP="${pkgs.slurp}/bin/slurp"
    DATE="${pkgs.coreutils}/bin/date"
    MKDIR="${pkgs.coreutils}/bin/mkdir"
    XDG_OPEN="${pkgs.xdg-utils}/bin/xdg-open"

    RUNTIME="''${XDG_RUNTIME_DIR:-/tmp}"
    PIDFILE="''${RUNTIME}/ww-wlrec.pid"
    STARTFILE="''${RUNTIME}/ww-wlrec.start"
    LASTFILE="''${RUNTIME}/ww-wlrec-lastfile"

    is_running() {
      if [[ -f "''${PIDFILE}" ]] && kill -0 "$(cat "''${PIDFILE}")" 2>/dev/null; then
        return 0
      else
        rm -f "''${PIDFILE}" 2>/dev/null || true
        return 1
      fi
    }

    focused_output() {
      if [[ -x "''${HYPR}" ]]; then
        "''${HYPR}" monitors -j | "''${JQ}" -r 'map(select(.focused==true))[0].name // empty'
      fi
    }

    start_common() {
      local geometry="''${1:-}"

      local dir="''${WLREC_DIR:-$HOME/Videos/ScreenRecordings}"
      "''${MKDIR}" -p "''${dir}"
      local ts="$("''${DATE}" +%Y-%m-%d_%H-%M-%S)"
      local file="''${WLREC_FILENAME:-record_''${ts}.mp4}"
      [[ "''${file}" = /* ]] || file="''${dir}/''${file}"

      local -a args=()
      if [[ -n "''${geometry}" ]]; then
        args+=( -g "''${geometry}" )
      else
        local out="''${WLREC_OUTPUT:-$(focused_output)}"
        [[ -n "''${out}" ]] && args+=( -o "''${out}" )
      fi

      [[ "''${WLREC_AUDIO:-1}" = "1" ]] && args+=( --audio )
      [[ -n "''${WLREC_AUDIO_DEVICE:-}" ]] && args+=( --audio-device "''${WLREC_AUDIO_DEVICE}" )
      [[ -n "''${WLREC_CODEC:-}" ]] && args+=( --codec "''${WLREC_CODEC}" )
      [[ -n "''${WLREC_MAX_FPS:-}" ]] && args+=( -m "''${WLREC_MAX_FPS}" )
      [[ -n "''${WLREC_BITRATE:-}" ]] && args+=( -b "''${WLREC_BITRATE}" )
      args+=( -f "''${file}" )

      nohup "''${WLS}" "''${args[@]}" >/dev/null 2>&1 &
      echo $! > "''${PIDFILE}"
      echo $! > "''${PIDFILE}"
      "''${DATE}" +%s > "''${STARTFILE}"
      echo "''${file}" > "''${LASTFILE}"
    }

    start() {
      if is_running; then exit 0; fi
      start_common
    }

   stop() {
  if is_running; then
    kill -INT "$(cat "''${PIDFILE}")" 2>/dev/null || true
    sleep 0.3
  fi

  # Por si no había PID o no respondió, intenta por nombre del proceso
  if pgrep -u "''${UID}" -x wl-screenrec >/dev/null 2>&1; then
    pkill -INT -u "''${UID}" -x wl-screenrec
    sleep 0.3
    if pgrep -u "''${UID}" -x wl-screenrec >/dev/null 2>&1; then
      pkill -TERM -u "''${UID}" -x wl-screenrec
    fi
  fi

  rm -f "''${PIDFILE}" 2>/dev/null || true
} 
    toggle() { if is_running; then stop; else start; fi; }

    region() {
      if is_running; then
        # Si ya hay grabación, detener (toggle de región)
        stop
      else
        # Selecciona región con slurp; cancela si no hay selección
        local geom
        geom="$("''${SLURP}" -f '%x,%y %wx%h' 2>/dev/null || true)"
        [[ -z "''${geom}" ]] && exit 0
        start_common "''${geom}"
      fi
    }

    open_dir() {
      local dir="''${WLREC_DIR:-$HOME/Videos/ScreenRecordings}"
      "''${MKDIR}" -p "''${dir}"
      "''${XDG_OPEN}" "''${dir}" >/dev/null 2>&1 &
    }

    status_json() {
      if is_running; then
        local start now elapsed mm ss file tip
        start=$(cat "''${STARTFILE}" 2>/dev/null || echo 0)
        now=$("''${DATE}" +%s)
        elapsed=$(( now - start ))
        mm=$(( elapsed / 60 ))
        ss=$(( elapsed % 60 ))
        file=$(cat "''${LASTFILE}" 2>/dev/null || echo "")
        tip="Grabando → ''${mm}:$(printf "%02d" "''${ss}")"
        [[ -n "''${file}" ]] && tip="''${tip}\n''${file}"
        printf '{"text":"REC %d:%02d","alt":"rec","class":"recording","tooltip":"%s"}\n' "''${mm}" "''${ss}" "''${tip}"
      else
        printf '{"text":"Idle","alt":"idle","class":"idle","tooltip":"Click: Monitor · Middle: Region · Derecho: Open Folder"}\n'
      fi
    }

    case "''${1:-status}" in
      start) start ;;
      stop) stop ;;
      toggle) toggle ;;
      region) region ;;
      open) open_dir ;;
      status|*) status_json ;;
    esac
  '';
in
{
  options.willwitcher.waybar.enable =
    mkEnableOption "Enable WillWitcher Waybar config (Stylix owns palette)";

  config = mkIf config.willwitcher.waybar.enable {

    # Stylix: Waybar tematizado pero sin inyectar CSS propio
    stylix.targets.waybar = {
      enable = true;
      addCss = false;
    };

    # Instala el wrapper y slurp
    home.packages = [ wlrec pkgs.slurp ];

    programs.waybar = {
      enable = true;

      style = mkForce ''
        * { font-size: 16px; } /* font-family lo pone Stylix */
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

        /* Estados del grabador */
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
          "modules-right"  = [ "custom/wlrec" "custom/notification" "pulseaudio" "tray" ];

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

          # Módulo de grabación
          "custom/wlrec" = {
            "return-type" = "json";
            "format" = " {icon} {text} ";
            "format-icons" = { "idle" = "⏺"; "rec" = "⏹"; }; # ⏺ grabar, ⏹ detener
            "exec-if" = "command -v ww-wlrec";
            exec = "ww-wlrec status";
            interval = 1;
            signal = 8;
            tooltip = true;

            # Clic izquierdo: alterna grabación del monitor enfocado
            "on-click" = "ww-wlrec toggle; pkill -RTMIN+8 waybar";

            # Clic medio: selecciona región (slurp) y alterna
            "on-click-middle" = "ww-wlrec region; pkill -RTMIN+8 waybar";

            # Clic derecho: abre carpeta de grabaciones
            "on-click-right" = "ww-wlrec open";
            "escape" = true;
          };
        }
      ];
    };
  };
}

