$env.config.buffer_editor = "nvim"
$env.path ++= ["~/.local/bin"]

# ============================
# Prompt with Nerd Font icons
# ============================

def create_left_prompt [] {
    # Current working directory and home
    let path = $env.PWD
    let home = ($env.HOME? | default "")

    # If path starts with $HOME, replace that part with "~"
    let display_path = if $home != "" and ($path | str starts-with $home) {
        $path | str replace $home "~"
    } else {
        $path
    }

    # User (optional)
    let user = ($env.USER? | default "")
    let user_segment = if $user == "" {
        ""
    } else {
        #  = user icon (Nerd Font)
        $"(ansi magenta) ($user)(ansi reset) "
    }

    #  = folder icon (Nerd Font)
    let dir_segment = $"(ansi blue) ($display_path)(ansi reset)"

    # Add a newline so the indicator goes on the next line
    $"($user_segment)($dir_segment)\n"
}


# Use our custom prompt function
$env.PROMPT_COMMAND = {|| create_left_prompt }

# No right prompt
$env.PROMPT_COMMAND_RIGHT = ""

# Prompt indicators (also a bit nicer)
$env.PROMPT_INDICATOR = "❯ "
$env.PROMPT_INDICATOR_VI_INSERT = ": "
$env.PROMPT_INDICATOR_VI_NORMAL = "❮ "
$env.PROMPT_MULTILINE_INDICATOR = "··· "

$env.config.show_banner = false

# ============================
# Aliases for nicer tools
# ============================

# Use lsd instead of ls
alias ls = ^lsd

# Use ripgrep instead of grep
alias grep = ^rg

# Use fd instead of find
alias find = ^fd

# =============================================================================
#
# Hook configuration for zoxide.
#

# Initialize hook to add new entries to the database.
export-env {
  $env.config = (
    $env.config?
    | default {}
    | upsert hooks { default {} }
    | upsert hooks.env_change { default {} }
    | upsert hooks.env_change.PWD { default [] }
  )
  let __zoxide_hooked = (
    $env.config.hooks.env_change.PWD | any { try { get __zoxide_hook } catch { false } }
  )
  if not $__zoxide_hooked {
    $env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | append {
      __zoxide_hook: true,
      code: {|_, dir| zoxide add -- $dir}
    })
  }
}

# =============================================================================
#
# When using zoxide with --no-cmd, alias these internal functions as desired.
#

# Jump to a directory using only keywords.
def --env --wrapped __zoxide_z [...rest: string] {
  let path = match $rest {
    [] => {'~'},
    [ '-' ] => {'-'},
    [ $arg ] if ($arg | path expand | path type) == 'dir' => {$arg}
    _ => {
      zoxide query --exclude $env.PWD -- ...$rest | str trim -r -c "\n"
    }
  }
  cd $path
}

# Jump to a directory using interactive search.
def --env --wrapped __zoxide_zi [...rest:string] {
  cd $'(zoxide query --interactive -- ...$rest | str trim -r -c "\n")'
}

# =============================================================================
#
# Commands for zoxide. Disable these using --no-cmd.
#

alias z = __zoxide_z
alias zi = __zoxide_zi

# =============================================================================
#
# Add this to your env file (find it by running `$nu.env-path` in Nushell):
#
#   zoxide init nushell | save -f ~/.zoxide.nu
#
# Now, add this to the end of your config file (find it by running
# `$nu.config-path` in Nushell):
#
#   source ~/.zoxide.nu
#
# Note: zoxide only supports Nushell v0.89.0+.
