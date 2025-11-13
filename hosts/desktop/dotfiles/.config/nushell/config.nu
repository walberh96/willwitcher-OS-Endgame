$env.config.buffer_editor = "nvim"
$env.path ++= ["~/.local/bin"]

# ============================
# Prompt with Nerd Font icons
# ============================

def create_left_prompt [] {
    # Current working directory
    let path_segment = $env.PWD

    # User (optional, in case $env.USER is not set)
    let user = ($env.USER? | default "")
    let user_segment = if $user == "" {
        ""
    } else {
        #  = user icon (Nerd Font)
        $"(ansi magenta) ($user)(ansi reset) "
    }

    #  = folder icon (Nerd Font)
    let dir_segment = $"(ansi blue) ($path_segment)(ansi reset)"

    # Join pieces into a single line
    $"($user_segment)($dir_segment)"
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
