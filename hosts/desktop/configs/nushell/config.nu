# ~/.config/nushell/config.nu

# Disable the startup banner and configure completions
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

# Aliases
alias find = fd
alias ls   = lsd
alias cat  = bat
