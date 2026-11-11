# dotfiles-mise

Personal dotfiles and workstation configuration, managed with
[mise](https://mise.jide.fr/), with secrets pulled from
[Bitwarden](https://bitwarden.com/) via [fnox](https://fnox.jdx.dev/).

The repo is cloned to `~/.dotfiles`, and `~/.config/mise` is symlinked to
`~/.dotfiles/.config/mise`, so the mise configuration in this repo *is* the
global mise configuration.

## Fresh machine setup

Requirements:

- Linux with `bash`, `curl`, `git`
- an **interactive terminal** (the bootstrap prompts for Bitwarden credentials)
- a Bitwarden account on the **EU server** (`https://vault.bitwarden.eu`),
  containing an item named `mise-ssh-config-personal` whose *notes* field holds
  the personal SSH config (rendered into `~/.ssh/config`)

Run **exactly** this command:

```bash
bash <(curl -sSf https://raw.githubusercontent.com/nikokultalahti/dotfiles-mise/main/bootstrap.sh)
```

### What the bootstrap does

`bootstrap.sh` performs three steps:

1. **Installs mise** (`curl -fsSL https://mise.run | sh`) and activates it.
2. **Clones this repo** to `~/.dotfiles` and symlinks
   `~/.config/mise` → `~/.dotfiles/.config/mise`.
3. **Authenticates Bitwarden and bootstraps**, via
   `mise exec bitwarden@latest fnox@latest -- bash -c '...'`: configures the EU
   server, `bw login`, `bw unlock` (exports `BW_SESSION`), then
   `fnox exec -- mise bootstrap`, which applies `.config/mise/config.toml`:
   - installs the CLI tools listed under `[tools]`
   - installs the Flatpak apps listed under `[bootstrap.packages]`
   - creates the directories under `[bootstrap.directories]` (e.g. `~/.ssh`
     with mode `0700`)
   - resolves the secrets under `[bootstrap.secrets]` from Bitwarden via fnox
   - copies / symlinks / templates the files listed under `[dotfiles]`
     (shell rc files, `.gitconfig`, editor configs, and `~/.ssh/config` rendered
     from `.ssh/config.tmpl` with the `SSH_CONFIG_PERSONAL` secret)
   - Switches git origin from the HTTPS to SSH for the repository

Afterwards, restart your terminal (or `source ~/.zshrc` / `~/.bashrc`) and
verify with `mise doctor`.

## Repository layout

| Path | Purpose |
|---|---|
| `bootstrap.sh` | Fresh-machine setup script (see above) |
| `.config/mise/config.toml` | Master mise config: settings, `[vars]`, `[tools]`, `[bootstrap.packages]`, `[bootstrap.directories]`, `[bootstrap.secrets]`, `[dotfiles]` |
| `.config/mise/fnox.toml` | fnox config: Bitwarden provider + `SSH_CONFIG_PERSONAL` secret (from Bitwarden item `mise-ssh-config-personal`, notes field) |
| `.config/mise/tasks/` | mise tasks, e.g. `install-vscode-extensions` (reads `extensions.yaml`) |
| `.bashrc` / `.zshrc` | Shell init: `PATH`, Bitwarden SSH agent socket (`SSH_AUTH_SOCK`), `mise activate`, starship / atuin / zoxide |
| `.gitconfig` | Git identity, SSH signing (`gpg.format=ssh`, `commit.gpgsign`), Commit as editor, git-lfs |
| `.ssh/config.tmpl` | Template for `~/.ssh/config`; contains `{{ secret(name="ssh_config_personal") }}` |
| `.config/atuin/`, `.config/bat/`, `.config/tealdeer/` | Tool configs |
| `.config/Code/User/settings.json` | VS Code settings |
| `.var/app/dev.zed.Zed/...` | Zed settings |

## Day-to-day usage

- **Edit dotfiles here**, then commit and push. The live config is managed by
  mise: check drift with `mise dot status` and re-apply everything with
  `fnox exec -- mise bootstrap`.
- **Secrets** never live in git. They are resolved at runtime by fnox from
  Bitwarden, e.g. `fnox exec -- mise <cmd>` (requires an unlocked vault:
  `export BW_SESSION=$(bw unlock --raw)`).
- **Tasks**: `mise run install-vscode-extensions` installs the VS Code
  extensions listed in `.config/mise/tasks/extensions.yaml`.
- **SSH** uses the Bitwarden desktop SSH agent:
  `SSH_AUTH_SOCK=$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock`
  (set in both `.bashrc` and `.zshrc`).
