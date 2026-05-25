# init.zsh - environment, PATH, tool initializers.

# Terminal compatibility (Ghostty)
export TERM=xterm-256color

# Editor
export EDITOR="${EDITOR:-nvim}"
export VISUAL="$EDITOR"

# Homebrew (auto-detects arch).
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Cargo / Rust
export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"
[[ -d "$CARGO_HOME/bin" ]] && PATH="$CARGO_HOME/bin:$PATH"

# Cursor CLI (installed via Homebrew cask)
if [[ -d "/Applications/Cursor.app/Contents/Resources/app/bin" ]]; then
    PATH="/Applications/Cursor.app/Contents/Resources/app/bin:$PATH"
fi

# Dotfiles bin/ (rebuild, update, doctor, edit-shell, edit-config wrappers)
DOTFILES_BIN="${DOTFILES_DIR:-$HOME/.dotfiles}/bin"
[[ -d "$DOTFILES_BIN" ]] && PATH="$DOTFILES_BIN:$PATH"

# fnm (Fast Node Manager) - ~2ms init vs nvm's ~300ms
# Supports .nvmrc and .node-version for automatic version switching.
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell zsh)"
fi

# zoxide (smarter cd with frecency)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# fzf integration (key bindings + completion)
if command -v fzf >/dev/null 2>&1; then
    FZF_SHELL_DIR="$(brew --prefix fzf 2>/dev/null)/shell"
    if [[ -d "$FZF_SHELL_DIR" ]]; then
        [[ -f "$FZF_SHELL_DIR/key-bindings.zsh" ]] && . "$FZF_SHELL_DIR/key-bindings.zsh"
        [[ -f "$FZF_SHELL_DIR/completion.zsh"   ]] && . "$FZF_SHELL_DIR/completion.zsh"
    fi
    export FZF_DEFAULT_COMMAND='fd --type f'
    export FZF_DEFAULT_OPTS='--height 40% --border'
fi

# eza
export EZA_ICONS_AUTO=1

# bat
export BAT_THEME="Catppuccin Mocha"
