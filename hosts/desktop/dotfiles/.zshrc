# ============================
# Oh My Zsh base
# ============================

# Path to your Oh My Zsh installation.

ZSH_THEME=""

# ============================
# Prompt estilo Nushell
# ============================
PROMPT=$'%F{magenta} %n%f %F{blue} %~%f\n❯ '

# ============================
# Aliases for nicer tools
# ============================

# Use lsd instead of ls
alias ls='lsd'

# Use ripgrep instead of grep
alias grep='rg'

# Use fd instead of find
alias find='fd'

# ============================
# zoxide
# ============================

eval "$(zoxide init zsh)"

source ~/.zsh/catpuccin-mocha-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/zsh-completions/zsh-completions.plugin.zsh
source ~/.zsh/sudo/sudo.plugin.zsh
source ~/.zsh/fzf/fzf.plugin.zsh
source ~/.zsh/git/git.plugin.zsh

