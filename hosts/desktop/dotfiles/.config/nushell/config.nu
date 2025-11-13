$env.config.buffer_editor = "nvim"
$env.path ++= ["~/.local/bin"]
# Nushell Config File
# All snippets are taken directly from the official Nushell Book.

########################
# 1) Prompt configuration
########################
# From: “Reedline, Nu's Line Editor” – Customizing the prompt
# https://www.nushell.sh/book/line_editor.html

def create_left_prompt [] {
    let path_segment = ($env.PWD)

    $path_segment
}

# The book also shows a create_right_prompt with date/time, but
# you requested *no* right prompt, so we do not use it.

$env.PROMPT_COMMAND = { create_left_prompt }

# From: “Configuration → Prompt Configuration”
# How to disable the right prompt
# https://www.nushell.sh/book/configuration.html
$env.PROMPT_COMMAND_RIGHT = ""

# Prompt indicators from the same Reedline chapter
$env.PROMPT_INDICATOR = "〉"
$env.PROMPT_INDICATOR_VI_INSERT = ": "
$env.PROMPT_INDICATOR_VI_NORMAL = "〉"
$env.PROMPT_MULTILINE_INDICATOR = "::: "


#############################################
# 2) command_not_found hook (NixOS example)
#############################################
# From: “Hooks” chapter – command_not_found on NixOS
# https://www.nushell.sh/book/hooks.html

$env.config.hooks.command_not_found = {
  |command_name|
  print (command-not-found $command_name | str trim)
}
