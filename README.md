# Personal Dotfiles (macOS)

Bare-shell macOS dotfiles. Homebrew for everything, `fnm` for Node,
`uv` + `pipx` for Python, Catppuccin theming, idempotent installer.

> **Status note:** the repo is named `nix-config` for legacy reasons.
> There is no Nix anywhere in the current setup. If you have an old Nix
> install on this machine, see `bin/uninstall-nix.sh` (optional, never
> auto-run).

## What it does

- Installs Homebrew (if missing) and applies a single `Brewfile` of
  formulae, casks, and taps.
- Symlinks repo-managed configs into `$HOME` (`~/.zshrc`, `~/.gitconfig`,
  `~/.ssh/config`, `~/.config/{starship.toml,ghostty/config,gh,bat,bottom,karabiner,nvim}`,
  Cursor `settings.json.defaults`).
- Renders Catppuccin flavor (`latte`/`frappe`/`macchiato`/`mocha`) into
  starship, ghostty, and Cursor configs at install time.
- Applies macOS preferences declaratively (Dock, Keyboard, Globe key,
  Default browser, Firewall) via `bin/macos-defaults.sh`.
- Sets a "More Space" display resolution per Mac model.
- Wires `fnm` (Node) and `uv`/`pipx` (Python) into the shell.

## Quick start (blank macOS)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/julienandreu/nix-config/main/install.sh)"
```

That clones to `~/.dotfiles` (override with `DOTFILES_DIR=...`) and runs
`setup.sh`, which:

1. Installs Homebrew if missing.
2. Prompts for a Catppuccin flavor.
3. Writes `~/.config/dotfiles/config.sh`.
4. Runs `bin/rebuild.sh` (`brew bundle` + symlinks + macOS defaults).
5. Configures git identity + SSH key for GitHub.
6. Optionally authenticates `gh`, installs Node LTS via `fnm`, installs
   Claude Code (`curl -fsSL https://claude.ai/install.sh | bash`) and
   OpenAI Codex (`npm i -g @openai/codex`).
7. Optionally runs `onboard.sh` (1Password, Cursor extensions, etc.).

## Daily use

| Situation                            | Command          |
|--------------------------------------|------------------|
| Edit shell init                      | `edit-shell`     |
| Edit any repo file                   | `edit-config`    |
| Apply local edits                    | `rebuild`        |
| Refresh brew + git pull              | `update`         |
| Brew upgrade only                    | `update --deps`  |
| Drift check (no changes)             | `update --check` |
| Diagnose                             | `doctor`         |
| Python install cheat sheet           | `py-help`        |

See [`docs/WORKFLOWS.md`](docs/WORKFLOWS.md) for recipe-style guidance.

## Layout

```
.
├── Brewfile                 # taps + formulae + casks
├── install.sh               # curl-pipeable bootstrap
├── setup.sh                 # first-run interactive flow
├── onboard.sh               # app login wizard (1Password, gh, Cursor...)
├── bin/
│   ├── rebuild.sh           # brew bundle + render + symlink + defaults
│   ├── update.sh            # git pull + brew upgrade + rebuild (4 modes)
│   ├── doctor.sh            # non-destructive diagnostics (+ --fix)
│   ├── edit-shell.sh        # open configs/zsh/init.zsh, prompt rebuild
│   ├── edit-config.sh       # open the repo in $EDITOR
│   ├── macos-defaults.sh    # `defaults write` + firewall + dockutil
│   ├── set-display.sh       # displayplacer per Mac model
│   ├── merge-cursor-settings.sh  # deep-merge defaults into Cursor settings.json
│   ├── uninstall-nix.sh     # optional, destructive, prompts YES
│   └── lib/                 # log / platform / config / symlink helpers
├── configs/
│   ├── zsh/{zshrc,init.zsh,aliases.zsh,functions.zsh,completion.zsh,plugins.zsh}
│   ├── starship/starship.toml.in     # Catppuccin palettes (all 4)
│   ├── ghostty/config.in             # templated flavor title
│   ├── git/config                    # delta pager + include ~/.config/dotfiles/git.local
│   ├── ssh/config                    # control-master + github/gitlab blocks
│   ├── gh/config.yml
│   ├── bat/config
│   ├── bottom/bottom.toml            # Catppuccin Mocha
│   ├── karabiner/karabiner.json      # Planck EZ profile
│   ├── cursor/settings.json.defaults.in
│   └── nvim/                         # standalone Neovim config
├── secrets/template.env              # env-style example (gitignored siblings)
├── docs/WORKFLOWS.md
└── README.md
```

## Machine-specific configuration

`setup.sh` writes `~/.config/dotfiles/config.sh`:

```sh
USERNAME="alice"
HOME_DIRECTORY="/Users/alice"
CATPPUCCIN_FLAVOR="mocha"   # latte|frappe|macchiato|mocha
ALLOW_GLOBAL_PIP="0"        # 1 to enable `doctor --fix` PEP-668 bypass
```

Personal git identity goes in `~/.config/dotfiles/git.local`
(included from the repo-managed `~/.gitconfig`):

```ini
[user]
    name = Alice Example
    email = alice@example.com
```

API keys go in `~/.config/dotfiles/secrets.env` (sourced by zsh init):

```sh
export ANTHROPIC_API_KEY="..."
export OPENAI_API_KEY="..."
```

All three files live outside the repo and are not tracked.

## Python (PEP 668)

Homebrew's Python ships an `EXTERNALLY-MANAGED` marker that blocks
`pip install` against the global interpreter. The supported workflows
on this machine:

```bash
pipx install <tool>          # isolated venv per CLI tool
uv tool install <tool>       # same idea, faster
uv venv && uv pip install …  # per-project virtualenv
```

Run `py-help` for a cheat sheet, or `doctor` to verify state. If you
really want global pip, set `ALLOW_GLOBAL_PIP=1` in `config.sh` and
run `doctor --fix`.

## Catppuccin flavor

The flavor is chosen interactively during `setup.sh` and stored in
`config.sh`. To change it later:

```bash
$EDITOR ~/.config/dotfiles/config.sh     # change CATPPUCCIN_FLAVOR=...
rebuild                                  # re-render templates
```

Starship and Ghostty pick up the new flavor immediately. Bat, bottom,
delta, and zsh-syntax-highlighting are vendored as Catppuccin Mocha
only - non-mocha flavors will look slightly off for those tools.

## Removing the old Nix install

If `/nix` still exists from a previous setup, **none of this repo
needs it**, but it stays out of your way until you remove it:

```bash
bin/uninstall-nix.sh    # prompts YES, then unloads daemon + rm -rf /nix
```

The script never runs without explicit confirmation.

## Updating

```bash
update           # git pull + brew bundle --upgrade + rebuild
update --deps    # brew upgrade only (no git pull)
update --local   # rebuild only (no git, no brew)
update --check   # report drift, no changes
```

## License

Personal config; no warranty.
