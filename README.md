# Personal Dotfiles (macOS)

Opinionated, idempotent dotfiles for a fresh macOS install. Plain shell,
nothing fancy:

- **Homebrew** drives every install (formulae, casks, taps) via a single `Brewfile`.
- **`fnm`** for Node version management, **`uv` + `pipx`** for Python.
- **Catppuccin** theming (latte / frappe / macchiato / mocha) across shell + terminal + editor.
- Repo-managed configs are **symlinked into `$HOME`** by one command (`rebuild`).
- macOS preferences (Dock, Keyboard, Firewall, Default browser) applied declaratively.
- Set up a blank Mac in ~10 minutes; one command after that for everything.

> The repo is named `nix-config` for legacy reasons. There is **no Nix**
> in the current setup. If you previously installed Nix on this machine,
> see [Removing an old Nix install](#removing-an-old-nix-install).

---

## Table of contents

1. [Quick start (blank Mac)](#quick-start-blank-mac)
2. [What gets installed](#what-gets-installed)
3. [Daily commands](#daily-commands)
4. [Customizing](#customizing)
   - [Change the Catppuccin flavor](#change-the-catppuccin-flavor)
   - [Add or remove a package](#add-or-remove-a-package)
   - [Add a new shell alias or function](#add-a-new-shell-alias-or-function)
   - [Add a new tool config](#add-a-new-tool-config)
   - [Per-machine secrets and identity](#per-machine-secrets-and-identity)
5. [Python (PEP 668)](#python-pep-668)
6. [Diagnosing problems](#diagnosing-problems)
7. [Repository layout](#repository-layout)
8. [How the installer works](#how-the-installer-works)
9. [Removing an old Nix install](#removing-an-old-nix-install)
10. [FAQ](#faq)

---

## Quick start (blank Mac)

One command. Works on a stock macOS (Apple Silicon or Intel):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/julienandreu/nix-config/main/install.sh)"
```

The installer:

1. Verifies macOS, installs **Xcode Command Line Tools** if missing.
2. Clones the repo to `~/.dotfiles` (override with `DOTFILES_DIR=...`).
3. Runs `setup.sh`, which walks you through:
   - Installing **Homebrew**.
   - Picking a **Catppuccin flavor** (default: mocha).
   - Writing `~/.config/dotfiles/config.sh`.
   - First **`rebuild`** (applies Brewfile, creates symlinks, sets macOS defaults).
   - **Git identity** -> `~/.config/dotfiles/git.local`.
   - Generating a **GitHub SSH key** + helping you add it to your account.
   - Optional: **`gh auth login`**, **Node LTS** via `fnm`, **Claude Code**
     (official installer), **OpenAI Codex** (npm global), and the **`onboard.sh`**
     wizard for 1Password / Cursor extensions / API keys.

When it finishes:

```bash
exec zsh        # reload your shell
doctor          # should be all green
```

That's the full first run. Everything after this is the [daily commands](#daily-commands).

---

## What gets installed

A single [`Brewfile`](Brewfile) is the source of truth. Categories:

| Category | Examples |
|---|---|
| **Core CLI** | `git`, `gh`, `awscli`, `neovim`, `starship`, `zsh-autosuggestions`, `zsh-syntax-highlighting` |
| **Rust-based utilities** | `ripgrep`, `fd`, `fzf`, `jq`, `zoxide`, `bat`, `eza`, `bottom`, `dust`, `sd`, `procs`, `git-delta`, `just`, `hyperfine`, `xh`, `tealdeer` |
| **Languages** | `fnm` (Node), `rust`, `rust-analyzer`, `python@3.13`, `ruff`, `pipx`, `uv` |
| **Dev tools** | `docker-compose`, `terraform`, `displayplacer`, `git-sweep`, `dockutil` |
| **GUI apps** | 1Password, Cursor, Docker Desktop, Ghostty, Google Chrome, Karabiner-Elements, Linear, Oneleet Agent, Slack |
| **Fonts** | MesloLG Nerd Font |
| **Taps** | `oneleet/tap`, `julienandreu/tap` |

Outside Homebrew (installed by `setup.sh` interactively):

- **Claude Code** via `curl -fsSL https://claude.ai/install.sh | bash`
- **OpenAI Codex** via `npm install -g @openai/codex` (needs Node from `fnm`)

---

## Daily commands

After installation, these are all on your PATH (provided by `configs/zsh/init.zsh`):

| Command | What it does |
|---|---|
| `rebuild` | Apply local edits: `brew bundle` + render templates + refresh symlinks + macOS defaults. Idempotent - safe to run anytime. |
| `update` | Pull the repo, `brew bundle --upgrade`, then `rebuild`. Full sync. Refuses if working tree is dirty. |
| `update --deps` | Same as `update` but skips `git pull`. |
| `update --local` | Just `rebuild`. Same as typing `rebuild`. |
| `update --check` | Drift check. Reports anything missing without changing the system. Exit 1 on drift. |
| `doctor` | Non-destructive diagnostics: platform, Homebrew + Brewfile drift, dotfiles config, symlink integrity, fnm + Node, Python + PEP 668 marker, AI assistants, `gh` auth, GUI apps, leftover `/nix`. |
| `doctor --fix` | Opt-in fixes (currently: disables PEP-668 marker if `ALLOW_GLOBAL_PIP=1`). |
| `edit-shell` | Open `configs/zsh/init.zsh` in `$EDITOR`; prompt to `rebuild` on save. |
| `edit-config` | Open the repo root in `$EDITOR`. |
| `py-help` | Print the Python install cheat sheet. |

See [`docs/WORKFLOWS.md`](docs/WORKFLOWS.md) for the recipe-style version of this table.

---

## Customizing

All customization is in two places:

1. **The repo** (committed): `Brewfile`, `configs/*`, `bin/*`.
2. **Per-machine config** (gitignored, in `~/.config/dotfiles/`): `config.sh`, `git.local`, `secrets.env`.

### Change the Catppuccin flavor

```bash
$EDITOR ~/.config/dotfiles/config.sh   # change CATPPUCCIN_FLAVOR=...
rebuild                                # re-render templates
exec zsh                               # reload prompt
```

Valid values: `latte`, `frappe`, `macchiato`, `mocha`.

Re-renders correctly: **starship**, **ghostty**, **Cursor** theme + icons.
Vendored as Mocha only (slight off-color on non-mocha): **bat**, **bottom**,
**delta**, **zsh-syntax-highlighting**.

### Add or remove a package

```bash
$EDITOR Brewfile     # add: brew "rclone"  or:  cask "obsidian"
rebuild              # applies it
```

To upgrade what's already installed:

```bash
update --deps        # brew bundle --upgrade
```

To audit what would change without applying:

```bash
update --check
```

### Add a new shell alias or function

Aliases live in [`configs/zsh/aliases.zsh`](configs/zsh/aliases.zsh).
Functions live in [`configs/zsh/functions.zsh`](configs/zsh/functions.zsh).

Both files are **symlinked live**, so:

```bash
$EDITOR configs/zsh/aliases.zsh
exec zsh             # no rebuild needed
```

### Add a new tool config

1. Drop the file into `configs/<tool>/<file>`.
2. Add an `ensure_symlink` line in
   [`bin/rebuild.sh`](bin/rebuild.sh) inside `stage_symlinks()`:
   ```bash
   ensure_symlink "$DOTFILES_DIR/configs/<tool>/<file>" "$HOME/.config/<tool>/<file>"
   ```
3. Run `rebuild`.

If the config needs Catppuccin flavor substitution, name the source
`<file>.in` and use the placeholders `__CATPPUCCIN_FLAVOR__` and
`__CATPPUCCIN_FLAVOR_TITLE__`. Then add a `render_template` call in
`stage_render_templates()` and symlink the rendered output (from
`~/.cache/dotfiles/rendered/`).

### Per-machine secrets and identity

Three gitignored files live in `~/.config/dotfiles/`:

**`config.sh`** (written by `setup.sh`; the dotfiles entrypoint):

```sh
USERNAME="alice"
HOME_DIRECTORY="/Users/alice"
CATPPUCCIN_FLAVOR="mocha"
ALLOW_GLOBAL_PIP="0"
```

**`git.local`** (written by `setup.sh`; included from the repo `~/.gitconfig`):

```ini
[user]
    name = Alice Example
    email = alice@example.com
```

**`secrets.env`** (written by `onboard.sh` for API keys; sourced by `zsh`):

```sh
export ANTHROPIC_API_KEY="..."
export OPENAI_API_KEY="..."
# Any other env vars you want available in interactive shells
```

To add a new secret manually:

```bash
$EDITOR ~/.config/dotfiles/secrets.env
exec zsh
```

The file is `chmod 600` when `onboard.sh` creates it; do the same if you
create it by hand.

---

## Python (PEP 668)

Homebrew's Python 3.13 ships an `EXTERNALLY-MANAGED` marker that blocks
`pip install` against the system interpreter. **This is intentional and you
should not work around it.** Use one of these supported flows:

```bash
pipx install <tool>          # one-off CLI tools (poetry, ansible, etc.)
uv tool install <tool>       # same idea, faster
uv venv && uv pip install …  # per-project virtualenv (recommended)
```

`py-help` prints the cheat sheet at any time. `doctor` reports the marker state.

If you really need global `pip install` (you don't), opt in:

```bash
$EDITOR ~/.config/dotfiles/config.sh   # set ALLOW_GLOBAL_PIP="1"
doctor --fix                           # renames EXTERNALLY-MANAGED -> .disabled
```

---

## Diagnosing problems

```bash
doctor
```

Runs 10 categories of checks. Exit codes:

- **0** - all blocking checks passed (warnings are fine)
- **1** - one or more blocking checks failed
- **2** - invalid arguments

Common conditions and fixes:

| Symptom in `doctor` | Fix |
|---|---|
| `Missing ~/.config/dotfiles/config.sh` | Run `./setup.sh` (or copy the snippet from [Per-machine secrets](#per-machine-secrets-and-identity)). |
| `~/.zshrc is not the expected symlink` | Run `rebuild`. |
| `Brewfile drift` | Run `update --deps` (or `rebuild`). |
| `No active Node` | `fnm install --lts && fnm default lts-latest`. |
| `Claude Code not installed` | `curl -fsSL https://claude.ai/install.sh \| bash`. |
| `Codex not installed` | `npm install -g @openai/codex`. |
| `gh not authenticated` | `gh auth login`. |
| `/nix still present` | Optional: `bin/uninstall-nix.sh` (prompts YES). |

---

## Repository layout

```
.
├── Brewfile                 # source of truth: taps + formulae + casks
├── install.sh               # curl-pipeable bootstrap (clones + execs setup.sh)
├── setup.sh                 # first-run interactive flow
├── onboard.sh               # app login wizard (1Password, Cursor extensions, API keys)
├── bin/
│   ├── rebuild.sh           # brew bundle + render + symlink + defaults
│   ├── update.sh            # git pull + brew upgrade + rebuild (4 modes)
│   ├── doctor.sh            # non-destructive diagnostics (+ --fix)
│   ├── edit-shell.sh        # open configs/zsh/init.zsh, prompt rebuild
│   ├── edit-config.sh       # open the repo in $EDITOR
│   ├── macos-defaults.sh    # `defaults write` + firewall + dockutil
│   ├── set-display.sh       # displayplacer per Mac model
│   ├── merge-cursor-settings.sh  # deep-merge into Cursor settings.json
│   ├── uninstall-nix.sh     # optional, destructive, prompts YES
│   └── lib/                 # log / platform / config / symlink helpers
├── configs/
│   ├── zsh/{zshrc,init.zsh,aliases.zsh,functions.zsh,completion.zsh,plugins.zsh}
│   ├── starship/starship.toml.in     # all four Catppuccin palettes inline
│   ├── ghostty/config.in             # templated flavor (title case)
│   ├── git/config                    # delta pager + include ~/.config/dotfiles/git.local
│   ├── ssh/config                    # control-master + github/gitlab blocks
│   ├── gh/config.yml
│   ├── bat/config
│   ├── bottom/bottom.toml            # Catppuccin Mocha
│   ├── karabiner/karabiner.json      # Planck EZ keyboard profile
│   ├── cursor/settings.json.defaults.in
│   └── nvim/                         # standalone Neovim config
├── secrets/template.env              # env-style example (gitignored siblings)
├── docs/WORKFLOWS.md
└── README.md
```

Outside the repo:

```
~/.config/dotfiles/
├── config.sh        # machine identity + flavor (written by setup.sh)
├── git.local        # personal git user.name + email
└── secrets.env      # API keys (chmod 600)

~/.cache/dotfiles/
└── rendered/        # template outputs (regenerated by rebuild)
```

---

## How the installer works

Three layers:

1. **`install.sh`** - the curl-pipeable bootstrap. Verifies macOS, installs
   Xcode CLT, clones to `$DOTFILES_DIR`, execs `setup.sh`.
2. **`setup.sh`** - one-time interactive flow. Installs Homebrew, prompts for
   flavor, writes `~/.config/dotfiles/config.sh`, runs `bin/rebuild.sh`, then
   walks through git + SSH + gh + Node + Claude/Codex + onboard.
3. **`bin/rebuild.sh`** - the workhorse. Runs every time you change the
   `Brewfile` or anything under `configs/`. Stages:
   - `stage_brew` - `brew bundle --file=Brewfile`
   - `stage_render_templates` - sed-substitute `__CATPPUCCIN_FLAVOR__` and
     `__CATPPUCCIN_FLAVOR_TITLE__` in `*.in` files into `~/.cache/dotfiles/rendered/`
   - `stage_symlinks` - idempotent `ensure_symlink` for each config; backs up
     non-symlink targets to `*.backup.YYYYMMDD-HHMMSS`
   - `stage_cursor_merge` - runs `bin/merge-cursor-settings.sh` (deep-merge defaults
     into Cursor's `settings.json` so user edits aren't clobbered)
   - `stage_macos_defaults` - `bin/macos-defaults.sh` (Dock, Keyboard, Firewall,
     Default browser - sudo for the firewall block)
   - `stage_set_display` - `bin/set-display.sh` (displayplacer per Mac model)

All stages are idempotent. Re-running `rebuild` with no changes is a no-op.

---

## Removing an old Nix install

If you migrated from a previous Nix-based setup, `/nix` is still on disk but
**nothing in this repo needs it**. Reclaim the space when you're confident the
new setup is working:

```bash
bin/uninstall-nix.sh
```

The script:

1. Prints exactly what it will do.
2. Requires you to type `YES` (uppercase) to proceed.
3. Unloads `nix-daemon` LaunchDaemons.
4. Kills lingering `nix-daemon` / `nix` processes.
5. Unmounts `/nix` if it's a separate APFS volume, then `rm -rf /nix`.
6. Removes `~/.nix-profile`, `~/.nix-defexpr`, `~/.nix-channels`,
   `~/.local/state/nix`.
7. Comments out any `.nix-profile` source lines in `~/.zshrc`, `~/.bash_profile`,
   `~/.profile`, `~/.bashrc` (backs up to `*.pre-nix-uninstall`).

It is **never run automatically**.

---

## FAQ

**Q: I want to install something without putting it in the Brewfile.**
Just `brew install <thing>` directly. The Brewfile is declarative state, not a
gate. `brew bundle` won't remove things outside the Brewfile (only `brew bundle
cleanup` would, and you have to run that manually).

**Q: Can I edit `~/.zshrc` directly?**
You can, but it's a symlink into the repo, so your edit lands in
`configs/zsh/zshrc` and gets committed by accident. Edit `configs/zsh/init.zsh`
(or `aliases.zsh` / `functions.zsh`) and use `edit-shell` for the right path.

**Q: What if I want Linux support?**
Not in scope right now. The repo assumes macOS (firewall, Dock, displayplacer,
Karabiner are all macOS-specific). Linux support would mean a parallel set of
config paths and a package-manager abstraction.

**Q: Can multiple machines share this repo?**
Yes - all machine-specific state lives in `~/.config/dotfiles/`, which is
outside the repo. Same checkout, different `config.sh` per machine.

**Q: How do I roll back if something goes wrong?**
`git log` and `git revert` like any repo. Symlink targets back up to
`*.backup.YYYYMMDD-HHMMSS`. macOS defaults can be inspected with `defaults read
<domain>` and reset manually if needed.

**Q: How is this different from chezmoi / yadm / nix-darwin / a Brewfile in a
gist?**
Less flexible than chezmoi (no templates beyond Catppuccin), less powerful than
nix-darwin (no atomic system state), but easier to read and faster to onboard.
The target audience is "one person, one or two machines, wants to set up a Mac
in under 15 minutes."

---

## License

Personal config; no warranty. Steal whatever's useful.
