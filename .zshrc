autoload -U compinit
compinit

# Ensure ~/bin and ~/.local/bin are in $PATH
if ! [[ "$PATH" =~ $HOME/bin ]]; then
    PATH="$HOME/bin:$PATH"
fi
if ! [[ "$PATH" =~ $HOME/.local/bin: ]]; then
    PATH="$HOME/.local/bin:$PATH"
fi
export PATH

# Bitwarden SSH agent
export SSH_AUTH_SOCK="$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock"

# Initialize CLI tools
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Set up fzf key bindings and fuzzy completion
if command -v fzf >/dev/null 2>&1; then
    # shellcheck source=/dev/null
    source <(fzf --zsh)
fi

# Add Carapace completions
if command -v carapace >/dev/null 2>&1; then
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
    zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
    # shellcheck source=/dev/null
    source <(carapace _carapace)
fi

# zsh-autosuggestions and zsh-syntax-highlighting
source "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null || true
source "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null || true

# ==============================================================================
# ALIASES
# ==============================================================================
if command -v eza >/dev/null 2>&1; then
    alias ll='eza -al --icons=auto --group-directories-first'
    alias l.='eza -d .*'
    alias ls='eza'
    alias l1='eza -1'
fi

alias cat='bat --style=plain --pager=never' 2>/dev/null

alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'

alias k='kubectl'
