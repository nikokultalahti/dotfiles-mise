#!/usr/bin/env bash
# # Bootstrap a new machine with mise and dotfiles.

# Usage on a fresh machine (requires bash and an interactive terminal).
# NOTE: do NOT pipe into bash (`curl ... | bash`) — then stdin is the script
# pipe and the interactive `bw login`/`bw unlock` prompts read EOF and fail.
#   bash <(curl -sSf https://raw.githubusercontent.com/nikokultalahti/dotfiles-mise/main/bootstrap.sh)

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/nikokultalahti/dotfiles-mise.git}"
# Exported because the `mise exec ... -- bash -c '...'` block below is
# single-quoted: the inner shell expands $REPO_DIR/$MISE_DIR itself and only
# sees variables that are exported.
export REPO_DIR="$HOME/.dotfiles"
export MISE_DIR="$HOME/.config/mise"

echo "------------------------------------------------------------"
echo "Workstation Bootstrap (Mise + Bitwarden + Fnox)"
echo "------------------------------------------------------------"
echo ""

# 1. Install & Activate Mise
if ! command -v mise &>/dev/null && [ ! -x "$HOME/.local/bin/mise" ]; then
    echo "[1/3] Installing Mise..."
    curl -fsSL https://mise.run | sh
    echo "[✓] Mise installed"
else
    echo "[1/5] Mise is already installed"
fi

export PATH="$HOME/.local/bin:$PATH"
CURRENT_SHELL="$(basename "${SHELL:-bash}")"
eval "$("$HOME/.local/bin/mise" activate "$CURRENT_SHELL" 2>/dev/null || "$HOME/.local/bin/mise" activate bash)"

# Step 2: Clone the dotfiles and seed global mise config
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "[2/3] Cloning $DOTFILES_REPO to $REPO_DIR..."
    mkdir -p "$HOME/.config"
    git clone "$DOTFILES_REPO" "$REPO_DIR"
    echo "[✓] Dotfiles cloned"
else
    echo "[2/3] Repo already present at $REPO_DIR"
fi
ln -s ~/.dotfiles/.config/mise "$MISE_DIR"

# Step 3. Authenticate Bitwarden and run bootstrap through fnox
# bitwarden/fnox are pulled in via `mise exec` here instead of `mise use -g`:
# `mise use -g` would write ~/.config/mise/config.toml
# ------------------------------------------------------------------------------
echo "[3/3] Preparing Bitwarden + fnox and running bootstrap..."
# shellcheck disable=SC2016
mise exec bitwarden@latest fnox@latest -- bash -c '
    set -euo pipefail

    echo "[-] Configuring Bitwarden server..."
    CURRENT_SERVER=$(bw config server 2>/dev/null || true)
    if [[ "$CURRENT_SERVER" != "https://vault.bitwarden.eu" ]]; then
        bw config server https://vault.bitwarden.eu
        echo "[✓] Bitwarden server configured"
    else
        echo "[✓] Bitwarden server already configured"
    fi

    if ! bw login --check &>/dev/null; then
        echo "[-] Logging in to Bitwarden..."
        bw login
    else
        echo "[✓] Bitwarden already logged in"
    fi

    echo "[-] Unlocking Bitwarden vault..."
    BW_SESSION="$(bw unlock --raw)"
    export BW_SESSION
    echo "[✓] Bitwarden vault unlocked"

    cd "$MISE_DIR"
    echo "[-] Running bootstrap through fnox..."
    fnox exec -- mise bootstrap
'

echo "-----------------------------"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
echo "  2. Verify with: mise doctor"
echo "  3. Check dotfiles: mise dot status"
