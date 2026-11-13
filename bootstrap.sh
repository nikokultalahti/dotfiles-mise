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

# 1. Install Mise
if ! command -v mise &>/dev/null && [ ! -x "$HOME/.local/bin/mise" ]; then
    echo "[1/4] Installing Mise..."
    curl -fsSL https://mise.run | sh
    echo "[✓] Mise installed"
else
    echo "[1/4] Mise is already installed"
fi

export PATH="$HOME/.local/bin:$PATH"

# Step 2: Ask for the machine role (personal or work)
# Asked before anything is cloned, so quitting here leaves the machine untouched.
# The role is saved in step 3 to ~/.config/mise/miserc.local.toml, before
# bootstrap runs, so mise loads config.<role>.toml with no -E flag, now and on
# every later run. It is only asked on a machine that has no such file yet. Set
# MACHINE_ROLE to skip the prompt; it also changes the role of an already
# bootstrapped machine.
# (~/.config/mise is a real directory, so that file lives outside the repo.)
ROLE="${MACHINE_ROLE:-}"
if [ -z "$ROLE" ] && [ ! -f "$MISE_DIR/miserc.local.toml" ]; then
    until [ "$ROLE" = "personal" ] || [ "$ROLE" = "work" ]; do
        read -r -p "[2/4] Machine role [personal/work]: " ROLE
    done
fi
case "$ROLE" in
    personal | work | "") ;; # empty: the existing miserc.local.toml stays
    *)
        echo "MACHINE_ROLE must be 'personal' or 'work', got '$ROLE'" >&2
        exit 1
        ;;
esac

# Step 3: Clone the dotfiles, seed global mise config and save the machine role
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "[3/4] Cloning $DOTFILES_REPO to $REPO_DIR..."
    mkdir -p "$HOME/.config"
    git clone "$DOTFILES_REPO" "$REPO_DIR"
    echo "[✓] Dotfiles cloned"
else
    echo "[3/4] Repo already present at $REPO_DIR"
fi

# ~/.config/mise is a real directory. The first bootstrap below runs from the
# repo's .config/mise, and its `[dotfiles]` entry (symlink-each) links every repo
# file into this directory, which mise then reads as its global config. The role
# file stays here, outside the repo.
# Older layout: ~/.config/mise was one link to the repo folder, which put the
# role file inside the repo. Replace the link and move the role file with it.
if [ -L "$MISE_DIR" ]; then
    rm "$MISE_DIR"
    mkdir -p "$MISE_DIR"
    if [ -f "$REPO_DIR/.config/mise/miserc.local.toml" ]; then
        mv "$REPO_DIR/.config/mise/miserc.local.toml" "$MISE_DIR/miserc.local.toml"
    fi
fi
mkdir -p "$MISE_DIR"

if [ -n "$ROLE" ]; then
    printf 'env = ["%s"]\n' "$ROLE" > "$MISE_DIR/miserc.local.toml"
    echo "[✓] Machine role saved: $ROLE"
fi

# Step 4. Authenticate Bitwarden and run bootstrap through fnox
# bitwarden/fnox are pulled in via `mise exec` here instead of `mise use -g`:
# `mise use -g` would write ~/.config/mise/config.toml
# ------------------------------------------------------------------------------
echo "[4/4] Preparing Bitwarden + fnox and running bootstrap..."
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

    # The first run reads the config of the repo as project config (and, once its
    # dotfiles are applied, ~/.config/mise as global config), so it needs trust.
    # Trusting config.toml also covers the config.<env>.toml files next to it.
    mise trust "$REPO_DIR/.config/mise/config.toml"
    cd "$REPO_DIR/.config/mise"
    echo "[-] Running bootstrap through fnox..."
    fnox exec -- mise bootstrap
'

echo "-----------------------------"
echo ""
echo "Next steps:"
echo '  1. Restart your terminal (or run: exec "$SHELL")'
echo "  2. Verify with: mise doctor"
echo "  3. Check dotfiles: mise dot status"
