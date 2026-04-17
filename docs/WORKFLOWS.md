# Workflows

Common recipes for daily use of this config.

> If the repo is not cloned to `~/.nix-config`, export
> `NIX_CONFIG_DIR=/absolute/path/to/repo` before using the aliases below
> (or edit directly in `$NIX_CONFIG_DIR`).

## Change your shell config

```bash
edit-shell         # opens modules/theme.nix in $EDITOR, prompts rebuild on save
```

You never need to edit `~/.zshrc` directly — it is a symlink into the
read-only Nix store. The active copy is regenerated from `modules/theme.nix`
on every rebuild.

## Add or remove a package

1. Edit the appropriate file:
   - `modules/software.nix` — development tools (Docker, Terraform, AWS CLI)
   - `modules/languages.nix` — language toolchains
   - `modules/tools.nix` — CLI utilities, Neovim
   - `modules/theme.nix` — shell / terminal / prompt
   - `machines/default.nix` — macOS system settings, Homebrew casks
2. `nix-rebuild` (alias for `./update.sh --local`)

## Install a Python CLI

PEP 668 blocks global `pip install` on this machine (Homebrew Python and
Nix Python both ship an `EXTERNALLY-MANAGED` marker). Use one of:

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

## Apply local edits (no pull, no dep bump)

```bash
nix-rebuild   # = ./update.sh --local
```

Runs a targeted Nix evaluation pre-flight, then `darwin-rebuild switch`.
Does **not** touch git or Homebrew. Safe with uncommitted changes.

## Refresh dependency versions

```bash
nix-update   # = ./update.sh --deps
```

Runs `nix flake update`, pre-flight eval, then rebuild. No git pull.

## Full sync (pull, deps, rebuild)

```bash
./update.sh   # default: git pull --ff-only, brew tap/update, flake update, rebuild
```

Fails fast on git divergence, failed brew tap, or eval errors.

## Validate without activating

```bash
./update.sh --check   # darwin-rebuild build (produces ./result, no switch)
```

Use when you want to check a config change without sudo.

## Diagnose problems

```bash
nix-doctor   # = ./scripts/doctor.sh
```

Non-destructive. Reports the state of `brew`, `darwin-rebuild`,
`home-manager`, the `~/.zshrc` symlink, `local/secrets.nix`, targeted
flake evaluation, and the active `python3` plus its PEP 668 marker.

Exit codes:
- `0` — all blocking checks passed (warnings allowed)
- `1` — one or more blocking checks failed
- `2` — invalid arguments

## Quick reference

| Situation | Command |
|---|---|
| Edit shell prompt / zsh init | `edit-shell` |
| Edit flake top level | `edit-config` |
| Apply local edits | `nix-rebuild` |
| Refresh flake.lock | `nix-update` |
| Full sync from origin | `./update.sh` |
| Check without switch | `./update.sh --check` |
| Diagnose | `nix-doctor` |
| Python cheat sheet | `py-help` |
