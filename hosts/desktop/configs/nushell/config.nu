# ~/.config/nushell/config.nu

# 0) Make Nu let Starship fully control the prompt
let-env PROMPT_COMMAND = {|| "" }
let-env PROMPT_COMMAND_RIGHT = {|| "" }
let-env PROMPT_INDICATOR = {|| "" }
let-env PROMPT_MULTILINE_INDICATOR = {|| "" }

# 1) Disable banner and set completions
$env.config = (
  $env.config
  | upsert show_banner false
  | upsert completions {
      case_sensitive: false
      quick: true
      partial: true
      algorithm: "fuzzy"
      external: { enable: true, max_results: 100 }
    }
)

# 2) Aliases
alias find = fd
alias ls   = lsd
alias cat  = bat

# 3) Load Starship once
use ~/.cache/starship/init.nu
