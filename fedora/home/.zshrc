# ------------------------------------------------------------------------------
# Shell Guard
# ------------------------------------------------------------------------------

[[ -o interactive ]] || return

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------

export EDITOR='nvim'
export VISUAL='nvim'
export GOPATH="$HOME/go"

# ------------------------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------------------------

export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew"
path=(
  "$GOPATH/bin"
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOMEBREW_PREFIX/bin"
  "$HOMEBREW_PREFIX/sbin"
  $path
)
export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"

# ------------------------------------------------------------------------------
# Zellij
# ------------------------------------------------------------------------------

if [[ -z "${ZELLIJ:-}" && -z "${SSH_CONNECTION:-}" && "${TERM:-}" != "dumb" ]] && command -v zellij >/dev/null 2>&1; then
  exec zellij attach --create AutanaSoft
fi

# ------------------------------------------------------------------------------
# History
# ------------------------------------------------------------------------------

HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$HOME/.zsh_history"
setopt append_history share_history hist_ignore_dups hist_ignore_space hist_reduce_blanks

# ------------------------------------------------------------------------------
# Runtime
# ------------------------------------------------------------------------------

command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)

if command -v bat >/dev/null 2>&1; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# ------------------------------------------------------------------------------
# Prompt
# ------------------------------------------------------------------------------

if [[ "${TERM:-}" != "dumb" ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ------------------------------------------------------------------------------
# Zsh Plugins
# ------------------------------------------------------------------------------

[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ------------------------------------------------------------------------------
# Aliases
# ------------------------------------------------------------------------------

alias oc='opencode --port 4096'
alias n='nvim'
alias cl='clear'

if command -v dnf >/dev/null 2>&1; then
  alias dnfi='sudo dnf install'
  alias dnfu='sudo dnf upgrade --refresh'
  alias dnfr='sudo dnf remove'
  alias dnfs='dnf search'
  alias dnfin='dnf info'
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza -lh --icons=auto'
  alias ll='eza -lah --icons=auto --group-directories-first'
  alias la='eza -a --icons=auto --group-directories-first'
  alias tree='eza --tree --icons=auto --group-directories-first'
fi

# ------------------------------------------------------------------------------
# Terminal Behavior
# ------------------------------------------------------------------------------

if [[ -t 0 ]]; then
  stty -ixon
fi
