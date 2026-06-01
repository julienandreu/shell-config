# init.zsh - environment, PATH, tool initializers.

# Keep PATH-like arrays free of duplicates.
typeset -U path cdpath fpath manpath

# Terminal compatibility (Ghostty)
export TERM=xterm-256color

# Editor
export EDITOR="${EDITOR:-nvim}"
export VISUAL="$EDITOR"

# History (mirrors nix-config: shared across sessions, dedup on write,
# ignore commands typed with a leading space).
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
mkdir -p "$(dirname "$HISTFILE")"
setopt HIST_FCNTL_LOCK HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
setopt NO_APPEND_HISTORY NO_EXTENDED_HISTORY NO_HIST_EXPIRE_DUPS_FIRST
setopt NO_HIST_FIND_NO_DUPS NO_HIST_IGNORE_ALL_DUPS NO_HIST_SAVE_NO_DUPS

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
    # Catppuccin Mocha palette (matches bat/delta theming).
    export FZF_DEFAULT_OPTS="--height 40% --border \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--color=border:#6c7086,label:#cdd6f4"
fi

# eza
export EZA_ICONS_AUTO=1

# bat
export BAT_THEME="Catppuccin Mocha"

# Personal secrets (gitignored). Sourced last so they win.
[[ -f "$HOME/.config/dotfiles/secrets.env" ]] && . "$HOME/.config/dotfiles/secrets.env"
