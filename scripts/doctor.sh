#!/usr/bin/env bash
set -euo pipefail

if (( $# > 0 )); then
    echo "error: doctor.sh does not accept arguments" >&2
    exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
FAILURES=0
WARNINGS=0

ok()   { printf '✓  %s\n' "$1"; }
warn() { printf '⚠  %s\n' "$1"; ((WARNINGS+=1)); }
fail() { printf '✗  %s\n' "$1"; ((FAILURES+=1)); }

echo "Nix config doctor — non-destructive diagnostics"
echo "Repo root: $REPO_ROOT"
echo ""

# --- CLI presence --------------------------------------------------------

if command -v brew >/dev/null 2>&1; then
    ok "brew on PATH"
else
    fail "brew not on PATH — install Homebrew or rerun ./setup.sh"
fi

if command -v darwin-rebuild >/dev/null 2>&1; then
    ok "darwin-rebuild on PATH"
else
    fail "darwin-rebuild not on PATH — start a fresh shell or rebuild from setup output"
fi

if command -v home-manager >/dev/null 2>&1; then
    ok "home-manager on PATH"
else
    warn "home-manager CLI not on PATH — not fatal for nix-darwin, but standalone HM commands will fail"
fi

# --- File state ----------------------------------------------------------

if [[ -L "$HOME/.zshrc" ]] && [[ "$(readlink "$HOME/.zshrc")" == /nix/store/* ]]; then
    ok "~/.zshrc is a Home Manager symlink"
else
    fail "~/.zshrc is not a Home Manager symlink into /nix/store"
fi

if [[ -f "$HOME/.config/nix-config/local/secrets.nix" ]]; then
    ok "local secrets file present"
else
    warn "local secrets file missing — run ./setup.sh if personal settings are incomplete"
fi

# --- Flake evaluation ----------------------------------------------------

if FLAKE_DIR="$REPO_ROOT" nix eval --raw --impure \
    "$REPO_ROOT#darwinConfigurations.mac.system.drvPath" >/dev/null 2>&1; then
    ok "targeted darwin configuration eval passes"
else
    fail "targeted darwin configuration eval failed — run ./update.sh --check"
fi

# --- Python / PEP 668 ----------------------------------------------------

if command -v python3 >/dev/null 2>&1; then
    py="$(command -v python3)"
    ok "python3 on PATH: $py"
    marker="$(
        python3 - <<'PY'
import pathlib, sysconfig
print(pathlib.Path(sysconfig.get_path("stdlib")) / "EXTERNALLY-MANAGED")
PY
    )"
    if [[ -f "$marker" ]]; then
        warn "active python is externally managed ($marker) — use pipx or uv, not global pip install"
    else
        ok "active python has no EXTERNALLY-MANAGED marker"
    fi
else
    fail "python3 not on PATH"
fi

# --- Summary -------------------------------------------------------------

echo ""
if (( FAILURES > 0 )); then
    printf 'doctor summary: %d failure(s), %d warning(s)\n' "$FAILURES" "$WARNINGS" >&2
    exit 1
fi

printf 'doctor summary: 0 failures, %d warning(s)\n' "$WARNINGS"
exit 0
