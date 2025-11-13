$env.config.buffer_editor = "nvim"
$env.path ++= ["~/.local/bin"]
# ============================
# Nushell config básico "from scratch"
# Prompt custom + completions avanzadas
# Asegúrate de usar una Nerd Font en tu terminal
# ============================

# ---------- Completions: fuzzy, rápidas ----------
$env.config.completions = {
  case_sensitive: false       # completions insensibles a mayúsculas
  quick: true                 # si solo queda una opción, la selecciona sola
  partial: true               # relleno parcial mientras escribes
  algorithm: "fuzzy"          # fuzzy matching (más cómodo)
  external: {
    enable: true              # busca también binarios en $env.PATH
    max_results: 100          # limitar resultados ayuda al rendimiento
    completer: null           # sin completer externo (todo es interno de Nu)
  }
}

# ---------- Menús de ayuda / completado / historia (Reedline) ----------
# Tab      -> menú de completado (columnar, con iconito)
# Ctrl + r -> menú de history
# F1       -> menú de ayuda
$env.config.menus ++= [
  {
    name: help_menu
    only_buffer_difference: true
    marker: " "                 # Nerd Font "?"
    type: {
      layout: description
      columns: 4
      col_width: 20
      col_padding: 2
      selection_rows: 4
      description_rows: 10
    }
    style: {
      text: green
      selected_text: green_reverse
      description_text: yellow
    }
  }
  {
    name: completion_menu
    only_buffer_difference: false
    marker: " "                 # flecha Nerd Font
    type: {
      layout: columnar
      columns: 4
      col_width: 20
      col_padding: 2
    }
    style: {
      text: green
      selected_text: green_reverse
      description_text: yellow
    }
  }
  {
    name: history_menu
    only_buffer_difference: true
    marker: " "                 # icono de reloj/history
    type: {
      layout: list
      page_size: 10
    }
    style: {
      text: green
      selected_text: green_reverse
      description_text: yellow
    }
  }
]

# ---------- Hook: command_not_found (NixOS friendly) ----------
# Cuando un comando no existe, usa la herramienta `command-not-found`
# de Nix para sugerir paquetes.
$env.config.hooks.command_not_found = {
  |cmd_name|
  command-not-found $cmd_name | str trim
}

# ---------- Info fija para el prompt (host) ----------
# Se calcula una sola vez al arrancar Nu, no en cada prompt.
let prompt_host = (try { hostname | str trim } catch { "" })
$env.PROMPT_HOST = $prompt_host

# ---------- Función auxiliar: estado de Git ----------
def prompt_git [] {
  # ¿Estamos dentro de un repo?
  let in_repo = (try {
      ^git rev-parse --is-inside-work-tree err> /dev/null
      | str trim
    } catch { "false" })

  if $in_repo != "true" {
    ""
  } else {
    # Rama actual (o hash corto si no hay ref simbólica)
    let branch = (try {
        ^git symbolic-ref --short HEAD err> /dev/null
        | str trim
      } catch {
        ^git rev-parse --short HEAD err> /dev/null
        | str trim
      })

    # `git status --porcelain=v1 -uno` es relativamente ligero
    let status_output = (try {
        ^git status --porcelain=v1 -uno err> /dev/null
        | str trim
      } catch { "" })

    let is_dirty = not ($status_output | is-empty)

    let branch_segment = $"(ansi cyan) ($branch)(ansi reset)"
    let state_icon = if $is_dirty {
      $"(ansi yellow) (ansi reset)"  # repo con cambios sin commitear
    } else {
      $"(ansi green) (ansi reset)"   # repo limpio
    }

    $" ($branch_segment)($state_icon)"
  }
}

# ---------- Prompt principal (solo izquierda, con Git) ----------
def create_left_prompt [] {
  # Ruta actual, con ~ para $HOME
  let cwd  = (pwd | str trim)
  let home = ($env.HOME? | default "")
  let path_display = if $home != "" and ($cwd | str starts-with $home) {
    $cwd | str replace $home "~"
  } else {
    $cwd
  }

  # user@host
  let user = ($env.USER? | default "")
  let host = ($env.PROMPT_HOST? | default "")
  let userhost = if $host == "" { $user } else { $"($user)@($host)" }
  let userhost_segment = if $userhost == "" {
    ""
  } else {
    $"(ansi magenta) ($userhost)(ansi reset)"
  }

  # Directorio con icono
  let path_segment = $"(ansi blue) ($path_display)(ansi reset)"

  # Segmento de Git (vacío si no es repo)
  let git_segment = (prompt_git)

  # Código de salida del último comando (convertido a int por si viene como string)
  let exit_code = (try { $env.LAST_EXIT_CODE | into int } catch { 0 })
  let status_icon = if $exit_code == 0 {
    $"(ansi green)(ansi reset)"
  } else {
    $"(ansi red)(ansi reset)"
  }

  # Duración del último comando (solo si > 1s, y convertido a int)
  let duration_ms = (try { $env.CMD_DURATION_MS | into int } catch { 0 })
  let duration_segment = if $duration_ms > 1000 {
    let secs = ($duration_ms / 1000)
    $"(ansi yellow) ($secs)s(ansi reset)"
  } else {
    ""
  }

  # Unimos solo los segmentos no vacíos para evitar dobles espacios
  let segments = [
    $status_icon
    $duration_segment
    $userhost_segment
    $path_segment
    $git_segment
  ]

  let non_empty = ($segments | where {|s| not ($s | is-empty) })
  let line = ($non_empty | str join " ")

  # Línea final: todo arriba, abajo la flecha de comando
  $"($line)\n❯ "
}

# ---------- Activar el prompt de Nushell ----------
$env.PROMPT_COMMAND = {|| create_left_prompt }

# Quitamos el right prompt (nada de hora/fecha a la derecha)
$env.PROMPT_COMMAND_RIGHT = ""

# Indicadores (dejamos la flecha en el propio prompt)
$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ""
$env.PROMPT_INDICATOR_VI_NORMAL = ""
$env.PROMPT_MULTILINE_INDICATOR = "::: "
