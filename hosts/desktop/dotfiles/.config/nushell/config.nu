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


#############################################
# 2) command_not_found hook (NixOS example)
#############################################

$env.config.hooks.command_not_found = {
  |command_name|
  print (command-not-found $command_name | str trim)
}
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

# Zoxide

def "nu-complete zoxide path" [context: string] {
    let parts = $context | str trim --left | split row " " | skip 1 | each { str downcase }
    let completions = (
        ^zoxide query --list --exclude $env.PWD -- ...$parts
            | lines
            | each { |dir|
                if ($parts | length) <= 1 {
                    $dir
                } else {
                    let dir_lower = $dir | str downcase
                    let rem_start = $parts | drop 1 | reduce --fold 0 { |part, rem_start|
                        ($dir_lower | str index-of --range $rem_start.. $part) + ($part | str length)
                    }
                    {
                        value: ($dir | str substring $rem_start..),
                        description: $dir
                    }
                }
            })
    {
        options: {
            sort: false,
            completion_algorithm: substring,
            case_sensitive: false,
        },
        completions: $completions,
    }
}
