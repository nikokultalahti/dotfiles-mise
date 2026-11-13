# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Set Bitwarden SSH agent for dev containers
export SSH_AUTH_SOCK="$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock"

# Activate mise: puts the mise-installed tools on PATH (safe to run twice, the
# NikOS image already activates it for login shells)
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi

# Interactive shells only: prompt, history, completions and aliases. These are
# the bash equivalents of what .zshrc sets up. zsh-autosuggestions and
# zsh-syntax-highlighting have no bash counterpart here.
if [[ $- == *i* ]]; then
    if command -v starship >/dev/null 2>&1; then
        eval "$(starship init bash)"
    fi

    if command -v atuin >/dev/null 2>&1; then
        eval "$(atuin init bash)"
    fi

    if command -v zoxide >/dev/null 2>&1; then
        eval "$(zoxide init bash)"
    fi

    # Set up fzf key bindings and fuzzy completion
    if command -v fzf >/dev/null 2>&1; then
        eval "$(fzf --bash)"
    fi

    # Add Carapace completions
    if command -v carapace >/dev/null 2>&1; then
        export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
        # shellcheck source=/dev/null
        source <(carapace _carapace bash)
    fi

    if command -v eza >/dev/null 2>&1; then
        alias ll='eza -al --icons=auto --group-directories-first'
        alias l.='eza -d .*'
        alias ls='eza'
        alias l1='eza -1'
    fi

    if command -v bat >/dev/null 2>&1; then
        alias cat='bat --style=plain --pager=never'
    fi

    alias ..='cd ..'
    alias ...='cd ../..'
    alias ~='cd ~'
fi

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
