# functions.zsh - shell functions.

# Python install cheat sheet.
# Prevents the "externally managed environment" (PEP 668) dead-end.
py-help() {
    cat <<'EOF'
Python workflow on this machine (PEP 668 blocks global pip install):

  CLI tools:     pipx install <tool>        # e.g. pipx install poetry
                 uv tool install <tool>     # alternative, faster

  Project env:   uv venv
                 source .venv/bin/activate
                 uv pip install <pkg>

  Notes:         avoid global 'pip install' against Homebrew python
                 run 'rebuild' after Brewfile edits
                 run 'doctor' for diagnostics
EOF
}
