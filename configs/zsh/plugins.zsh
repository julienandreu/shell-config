# plugins.zsh - autosuggestions + syntax highlighting from Homebrew formulae.
# Order: syntax-highlighting must be sourced LAST (after compdef calls).

BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

if [[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    . "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Catppuccin highlight palette (vendored).
CATPPUCCIN_HL="${DOTFILES_DIR:-$HOME/.dotfiles}/configs/zsh-plugins/catppuccin_${CATPPUCCIN_FLAVOR:-mocha}-zsh-syntax-highlighting.zsh"
[[ -f "$CATPPUCCIN_HL" ]] && . "$CATPPUCCIN_HL"

if [[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    . "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

unset BREW_PREFIX CATPPUCCIN_HL
