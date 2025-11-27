ZSH_THEME=""

# ============================
# Prompt
# ============================

PROMPT='%F{magenta} %n%f %F{blue} %~%f${vcs_info_msg_0_}
%(?.%F{green}❯%f.%F{red}❯%f) '
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
# Lightweight git info (vcs_info)
# ============================

autoload -Uz vcs_info

zstyle ':vcs_info:git:*' enable git
zstyle ':vcs_info:*' check-for-changes false
zstyle ':vcs_info:*' max-exports 2

zstyle ':vcs_info:git:*' formats ' %F{yellow} %b%f'
zstyle ':vcs_info:git:*' actionformats ' %F{yellow} %b|%a%f'

precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )

setopt prompt_subst

# ============================
# zoxide
# ============================

eval "$(zoxide init zsh)"

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/zsh-completions/zsh-completions.plugin.zsh

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

