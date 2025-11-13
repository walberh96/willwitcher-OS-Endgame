$env.config.buffer_editor = "nvim"
$env.path ++= ["~/.local/bin"]

# ============================
# Prompt with Nerd Font icons
# ============================

def create_left_prompt [] {
    # Current working directory and home
    let path = $env.PWD
    let home = ($env.HOME? | default "")

    # User (optional)
    let user = ($env.USER? | default "")
    let user_segment = if $user == "" {
        ""
    } else {
        #  = user icon (Nerd Font)
        $"(ansi magenta) ($user)(ansi reset) "
    }

    # Directory segment:
    # - If in home: only the folder icon (colored)
    # - Else: folder icon + full path
    let dir_segment = if $home != "" and $path == $home {
        #  = folder icon (Nerd Font)
        $"(ansi blue)(ansi reset)"
    } else {
        $"(ansi blue) ($path)(ansi reset)"
    }

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
