# Workflows

Common recipes for daily use of this dotfiles repo.

> If the repo is not cloned to `~/.dotfiles`, export
> `DOTFILES_DIR=/absolute/path/to/repo` before running the scripts
> (or just use the bin/* commands directly via PATH).

## Change your shell config

```bash
edit-shell         # opens configs/zsh/init.zsh in $EDITOR, prompts rebuild on save
```

`~/.zshrc` is a symlink into the repo. Direct edits there are pointless;
edit `configs/zsh/*` in the repo and run `rebuild`.

## Add or remove a package

1. Edit `Brewfile` (formulae, casks, taps).
2. Run `rebuild` (or `update --deps` to also upgrade everything).

## Add a new shell alias / function

1. Edit `configs/zsh/aliases.zsh` or `configs/zsh/functions.zsh`.
2. Run `exec zsh` (no rebuild needed - files are symlinked live).

## Add a tool config file

1. Drop the file under `configs/<tool>/`.
2. Add an `ensure_symlink` line in `bin/rebuild.sh:stage_symlinks()`.
3. Run `rebuild`.

If the config needs Catppuccin flavor substitution, name the source
`<file>.in` and use `__CATPPUCCIN_FLAVOR__` / `__CATPPUCCIN_FLAVOR_TITLE__`
placeholders. Render via `render_template` in `stage_render_templates`.

## Install a Python CLI

Homebrew's Python blocks global `pip install` (PEP 668). Use one of:

```bash
pipx install <tool>      # isolated venv per tool, symlinked on PATH
uv tool install <tool>   # same idea, faster
```

Run `py-help` from any shell for a cheat sheet.

## Create a Python project environment

```bash
uv venv
source .venv/bin/activate
uv pip install <pkg>
```

## Override the PEP 668 marker (advanced)

If you really need global `pip install` against the Homebrew Python:

```bash
$EDITOR ~/.config/dotfiles/config.sh   # set ALLOW_GLOBAL_PIP="1"
doctor --fix                           # renames EXTERNALLY-MANAGED -> .disabled
```

Not recommended. The pipx/uv flows are easier and don't break the system.

## Apply local edits (no pull, no upgrade)

```bash
rebuild         # or: update --local
```

Runs `brew bundle` (idempotent), re-renders templated configs, refreshes
symlinks, applies macOS defaults. Safe with uncommitted changes.

## Refresh formulae/casks only

```bash
update --deps   # brew bundle --upgrade + rebuild
```

No git pull, no other side-effects.

## Full sync (pull, deps, rebuild)

```bash
update          # default: git pull --ff-only + brew bundle --upgrade + rebuild
```

Refuses to run if the working tree has uncommitted changes.

## Drift check (no changes)

```bash
update --check  # brew bundle check --verbose; exits 1 if drift
```

## Diagnose

```bash
doctor          # platform, brew, config, symlinks, fnm, python, ai, gh, apps, /nix
doctor --fix    # opt-in: disable EXTERNALLY-MANAGED if ALLOW_GLOBAL_PIP=1
```

Exit codes:
- `0` - all blocking checks passed (warnings allowed)
- `1` - one or more blocking checks failed
- `2` - invalid arguments

## Change Catppuccin flavor

```bash
$EDITOR ~/.config/dotfiles/config.sh   # CATPPUCCIN_FLAVOR="frappe"
rebuild
```

Starship and Ghostty re-render correctly. Bat/bottom/delta/zsh-highlight
are vendored as Mocha only.

## Add an API key for Claude / Codex / anything

```bash
$EDITOR ~/.config/dotfiles/secrets.env
exec zsh   # init.zsh sources secrets.env at the end
```

Permissions: the file lives in `~/.config/dotfiles/` and is `chmod 600`
when `onboard.sh` writes to it.

## Remove the old Nix install (optional)

```bash
bin/uninstall-nix.sh   # prompts YES; unloads daemon, rm -rf /nix, cleans rc files
```

The dotfiles never need /nix. This script is the only path that removes it.

## Quick reference

| Situation                            | Command          |
|--------------------------------------|------------------|
| Edit shell init                      | `edit-shell`     |
| Edit any repo file                   | `edit-config`    |
| Apply local edits                    | `rebuild`        |
| Refresh brew + git pull              | `update`         |
| Brew upgrade only                    | `update --deps`  |
| Drift check (no changes)             | `update --check` |
| Diagnose                             | `doctor`         |
| Python cheat sheet                   | `py-help`        |
| Remove Nix (optional)                | `bin/uninstall-nix.sh` |
