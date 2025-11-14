# ============================
# Oh My Zsh base
# ============================

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

# Plugins de Oh My Zsh
# (zsh-syntax-highlighting mejor al final)
plugins=(
  git
  fzf
  zsh-completions
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ============================
# Catppuccin syntax highlighting
# ============================

source ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh

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

