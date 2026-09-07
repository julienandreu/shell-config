# Brewfile - declarative Homebrew install manifest.
# Apply with: brew bundle --file=Brewfile  (or `rebuild`).
# Upgrade with: brew bundle --upgrade --file=Brewfile  (or `update --deps`).
# Cleanup unused: brew bundle cleanup --file=Brewfile  (manual).

# =============================================================================
# Taps
# =============================================================================
# `trusted: true` pre-authorizes the tap in ~/.homebrew/trust.json before any
# entry is loaded, so `brew bundle` never stops to ask "trust this tap?" on a
# fresh machine. Trusting a tap covers every formula and cask inside it
# (Homebrew::Trust.trusted? falls back to the tap), so the individual
# hashicorp/julienandreu entries below need no annotation of their own.
# Only ever set this on taps you actually vet: it means Homebrew will load and
# execute their Ruby without prompting.
tap "hashicorp/tap", trusted: true
tap "julienandreu/tap", trusted: true

# =============================================================================
# Core CLI tools
# =============================================================================
brew "git"
brew "gh"
brew "awscli"
brew "neovim"
brew "starship"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# =============================================================================
# Search, navigation, formatting (Rust-based CLI replacements)
# =============================================================================
brew "ripgrep"        # rg - grep replacement
brew "fd"             # find replacement
brew "fzf"            # fuzzy finder
brew "jq"             # JSON processor (kept: other tools shell out to it)
brew "jaq"            # jq replacement - drop-in CLI, faster
brew "zoxide"         # smarter cd
brew "dust"           # du - visual disk usage
brew "sd"             # sed - simpler find & replace
brew "procs"          # ps - colored process tables
brew "git-delta"      # syntax-highlighted git diffs (delta)
brew "just"           # make - command runner
brew "hyperfine"      # time - benchmarking
brew "xh"             # curl alternative
brew "eza"            # ls replacement
brew "bat"            # cat replacement
brew "bottom"         # top replacement (btm)
brew "tealdeer"       # tldr pages

# =============================================================================
# Programming languages & runtimes
# =============================================================================
brew "fnm"            # Node version manager (~150x faster than nvm)
brew "rust"           # rustc + cargo
brew "rust-analyzer"
brew "python@3.13"
brew "ruff"           # Python linter/formatter
brew "pipx"           # isolated Python CLI installs
brew "uv"             # fast Python package + venv manager

# =============================================================================
# Development tools
# =============================================================================
brew "docker-compose"
brew "hashicorp/tap/terraform"
brew "displayplacer"  # CLI display resolution
brew "julienandreu/tap/git-sweep"  # branch cleanup (from your own tap)

# =============================================================================
# macOS preferences plumbing (used by bin/macos-defaults.sh)
# =============================================================================
brew "dockutil"       # declarative dock persistent-apps

# =============================================================================
# GUI applications
# =============================================================================
cask "1password"
cask "cursor"
cask "docker-desktop"
cask "ghostty"
cask "google-chrome"
cask "karabiner-elements"
cask "linear"
cask "slack"

# Deliberately NOT managed here:
#   oneleet-agent - MDM/company-provisioned security agent. It self-updates
#   (auto_updates true), installs a root launchd daemon, and lives in a
#   third-party tap, so Homebrew's Caskroom version drifts from what's on disk
#   and re-install/upgrade needs root. Let MDM own it; install by hand if
#   needed:  brew install --cask oneleet/tap/oneleet-agent

# =============================================================================
# Fonts
# =============================================================================
cask "font-meslo-lg-nerd-font"

# =============================================================================
# Mac App Store apps (via mas)
# =============================================================================
# App Store exclusives, so there is no cask for them. `brew bundle` installs
# `mas` on demand, but it is declared explicitly so it shows up in the manifest
# and in `brew bundle check`.
#
# Caveat: `mas install` only works when the App Store is signed in AND the app
# is already in that Apple ID's purchase history ("obtained" at least once,
# even for free apps). On a brand-new Apple ID it will fail; that is now a
# non-fatal warning in `rebuild`, and the fallback is one click in the App
# Store. `id:` must be an unquoted Integer.
brew "mas"
mas "Amphetamine", id: 937984704   # keep-awake utility (no cask exists)
