########################################
# Basic environment
########################################

export SHELL=/bin/zsh
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less -R"

# Locale (adjust to your needs)
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Paths (tweak as you like)
path=(
  $HOME/.local/bin
  $HOME/bin
  $path
)

########################################
# History
########################################

HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

setopt HIST_IGNORE_DUPS       # ignore duplicate commands
setopt HIST_IGNORE_ALL_DUPS   # remove older duplicate entries
setopt HIST_REDUCE_BLANKS     # trim unnecessary blanks
setopt HIST_VERIFY            # don't execute expanded history right away
setopt EXTENDED_HISTORY       # timestamp history

setopt SHARE_HISTORY          # share history between zsh sessions

########################################
# Shell behavior & quality of life
########################################

setopt AUTO_CD                # `cd dir` -> just type `dir`
setopt AUTO_PUSHD             # use pushd instead of cd, keep directory stack
setopt PUSHD_IGNORE_DUPS
setopt CORRECT                # spelling correction for commands
setopt INTERACTIVE_COMMENTS   # allow comments in interactive shell

setopt COMPLETE_IN_WORD       # complete in the middle of a word
setopt NO_BEEP                # no bell
setopt GLOB_DOTS              # glob dotfiles with *

# Case-insensitive completion
zmodload zsh/complist
autoload -Uz compinit

# Use a cached compdump for speed
if [[ ! -d $HOME/.cache/zsh ]]; then
  mkdir -p $HOME/.cache/zsh
fi

compinit -d $HOME/.cache/zsh/zcompdump

########################################
# Keybindings
########################################

bindkey -e  # Emacs keybindings (default)

# Ctrl+R for history search (fzf will override if you map it there)
bindkey '^R' history-incremental-search-backward

########################################
# Modern tools aliases (lsd, fd, rg, bat)
########################################

# ---- lsd: modern ls with icons/tree ----
if command -v lsd >/dev/null 2>&1; then
  alias ls='lsd'
  alias ll='lsd -lh'         # long, human-readable
  alias la='lsd -A'          # all except . and ..
  alias lla='lsd -Alh'       # all + long + human-readable
  alias tree='lsd --tree'    # tree view
else
  # Fallback to classic ls if lsd is missing
  alias ls='ls --color=auto'
  alias ll='ls -lh'
  alias la='ls -A'
  alias lla='ls -Alh'
fi

# ---- bat: modern cat with syntax highlighting ----
if command -v bat >/dev/null 2>&1; then
  # Replace cat for interactive use (no pager by default)
  alias cat='bat --paging=never'
  alias batp='bat'                 # full bat with pager
  alias bate='bat --style=plain'   # no decorations, useful for piping
fi

# ---- fd: modern find (simple, fast) ----
if command -v fd >/dev/null 2>&1; then
  # Replace find for quick everyday usage
  alias find='fd'
  alias fda='fd -HI'          # include hidden + ignore .gitignore
  alias fdf='fd --type f'     # only files
  alias fdd='fd --type d'     # only directories
fi

# ---- ripgrep: modern grep ----
if command -v rg >/dev/null 2>&1; then
  alias grep='rg --color=auto'
  alias gi='rg -i'                         # case-insensitive
  alias gg='rg --hidden --glob "!.git"'    # include hidden, skip .git
fi

########################################
# FZF integration
# (Adjust paths depending on how you installed fzf)
########################################

# If you use the standard fzf install script:
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi
if [[ -f /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi

# Nice default options (no performance hit)
export FZF_DEFAULT_OPTS='--height=40% --border --info=inline --pointer="▶"'

########################################
# Plugins (syntax highlighting, autosuggestions, fzf-zsh)
# Adjust paths to where you cloned them.
########################################

# Example layout:
# ~/.config/zsh/plugins/
#   ├─ zsh-autosuggestions
#   ├─ zsh-syntax-highlighting
#   └─ fzf-zsh (or similar)

ZSH_PLUGIN_DIR="$HOME/.config/zsh/plugins"

# fzf-zsh plugin (if you're using one, e.g. zsh-users/zsh-fzf or similar)
if [[ -f "$ZSH_PLUGIN_DIR/fzf-zsh/fzf-zsh.plugin.zsh" ]]; then
  source "$ZSH_PLUGIN_DIR/fzf-zsh/fzf-zsh.plugin.zsh"
fi

# Autosuggestions (should be before syntax highlighting)
if [[ -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

  # Keep autosuggestions lightweight
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# Syntax highlighting MUST be last
if [[ -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

########################################
# Starship prompt
########################################

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

########################################
# Final tweaks
########################################

# Less annoying "less" defaults
export LESSHISTFILE=-
export LESS='-R'

# Don’t show “You have new mail”
unset MAILCHECK
