# Personal Nix Configuration

A reproducible macOS development environment using Nix, nix-darwin, and Home Manager. Set up your entire development workstation in minutes with a single command.

## 🎯 What This Provides

### System Configuration (via nix-darwin)
- **macOS Settings**: Dock, keyboard, firewall, default browser
- **Applications**: Homebrew casks automatically installed

### Development Environment (via Home Manager)
- **Terminal & Shell**: Ghostty terminal, Zsh with Starship prompt
- **Development Tools**: Git, Docker, GitHub CLI, AWS CLI, Terraform
- **Programming Languages**: Node.js (via fnm), Rust, Python
- **Modern CLI Tools**: Neovim, ripgrep, fd, bat, fzf, zoxide, and more
- **GUI Applications**: Cursor, Chrome, Docker Desktop, Slack, Linear, 1Password
- **Keyboard**: Karabiner Elements for custom keyboard mappings
- **Theme**: Catppuccin Mocha across all tools

## 📋 Prerequisites

- macOS (Apple Silicon or Intel)
- Admin access to your machine
- Internet connection

## 🚀 Installation

### One-Line Install (Recommended)

Run this command on a fresh Mac:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/julienandreu/nix-config/main/install.sh)"
```

This will:
1. Install Xcode Command Line Tools (if needed)
2. Clone repository to `~/.nix-config`
3. Install Nix package manager
4. Install Homebrew
5. Build and activate your system configuration
6. Guide you through personal setup (Git config, SSH keys, etc.)

### Post-Installation: Application Setup

After installation completes, run the onboarding wizard:

```bash
cd ~/.nix-config
./onboard.sh
```

This guides you through setting up:
- Chrome (default browser & sign-in)
- GitHub CLI (gh authentication)
- 1Password (password manager)
- AWS (console & CLI)
- Cursor (AI code editor)
- Docker Desktop (container platform)
- Linear (project management)
- Slack (team communication)
- AI Assistants (Claude Code & Codex)

### Manual Installation

If you prefer to clone first:

```bash
git clone https://github.com/julienandreu/nix-config.git ~/.nix-config
cd ~/.nix-config
./setup.sh
```

## 📁 Project Structure

```
nix-config/
├── flake.nix              # Main Nix flake entry point
├── home.nix               # Home Manager configuration
├── local.nix              # Machine-specific config (generated locally, gitignored)
│
├── install.sh             # Bootstrap installer
├── setup.sh               # Full interactive setup (Git, SSH, system build)
├── update.sh              # Update packages and rebuild
├── onboard.sh             # Application setup wizard
│
├── machines/
│   └── default.nix        # macOS system settings & Homebrew
│
├── modules/
│   ├── software.nix       # Dev tools (Git, Docker, AWS CLI, etc.)
│   ├── languages.nix      # Programming languages
│   ├── tools.nix          # CLI utilities & Neovim
│   └── theme.nix          # Shell theme & terminal config
│
├── configs/
│   └── nvim/              # Complete Neovim configuration
│
├── scripts/
│   └── merge-cursor-settings.sh  # Cursor settings merge script
│
└── secrets/
    ├── template.env       # Template for environment secrets
    └── template.nix       # Template for Nix secrets
```

## 🔄 Daily Usage

> **Recipe index**: see [docs/WORKFLOWS.md](docs/WORKFLOWS.md) for the short
> list of common situations → commands. The most-used aliases after install:
> `edit-shell`, `nix-rebuild`, `nix-update`, `nix-doctor`, `py-help`.

### Updating Your Configuration

Pull latest changes, refresh dependencies, and rebuild:

```bash
cd ~/.nix-config
./update.sh
```

This will:
- Pull from Git repository (fails fast on divergence)
- Update flake.lock (Nix dependencies)
- Rebuild and activate your configuration

Other modes:

```bash
./update.sh --local    # rebuild only (no git, no Homebrew) — for local edits
./update.sh --deps     # flake update + rebuild (no git pull)
./update.sh --check    # darwin-rebuild build, no switch (no sudo)
./update.sh --help     # show all modes

./scripts/doctor.sh    # non-destructive diagnostics
```

### Adding New Software

1. Edit the appropriate module in `modules/`:
   - `software.nix` - Development tools (Git, Docker, etc.)
   - `languages.nix` - Programming languages
   - `tools.nix` - CLI utilities
   - `theme.nix` - Shell and terminal configuration

2. For GUI apps, edit `machines/default.nix` (Homebrew casks section)

3. Rebuild:
   ```bash
   darwin-rebuild switch --flake ~/.nix-config#mac --impure
   ```

### Customizing Personal Settings

Personal settings (Git name/email, SSH keys, etc.) are stored in:
```
~/.config/nix-config/local/secrets.nix
```

This file is gitignored and created during `setup.sh`.

## 🛠️ Troubleshooting

### Command not found after installation

Start a new terminal session:
```bash
exec zsh
```

Or close and reopen your terminal.

### Nix build fails

Clean the Nix store and rebuild:
```bash
nix-collect-garbage -d
darwin-rebuild switch --flake ~/.nix-config#mac --impure
```

### Homebrew apps not installed

Homebrew casks install asynchronously. Check status:
```bash
brew list --cask
```

If an app is missing, install manually:
```bash
brew install --cask <app-name>
```

### Git configuration not applied

Ensure secrets file exists:
```bash
cat ~/.config/nix-config/local/secrets.nix
```

If missing, run `./setup.sh` to recreate it.

### SSH key not working

Test GitHub connection:
```bash
ssh -T git@github.com
```

If it fails, ensure your public key is added to GitHub:
```bash
cat ~/.ssh/id_ed25519_github.pub | pbcopy
# Then add to: https://github.com/settings/keys
```

## ✅ Verification

Check that everything is installed:

```bash
# Core tools
which nix darwin-rebuild brew

# Development tools
which git gh docker aws

# Languages
which node rustc python3
node --version
rustc --version

# CLI tools
which nvim rg fd fzf bat

# Shell
echo $SHELL
starship --version
```

## 🔐 Security

- Never commit `~/.config/nix-config/local/secrets.nix` (gitignored)
- SSH keys are stored in `~/.ssh/` (not managed by Nix)
- AWS credentials in `~/.aws/` (not managed by Nix)
- GitHub tokens managed by `gh auth` (stored securely)

## 📚 Key Features

### Fast Node.js Management
- **fnm** (Fast Node Manager) - 150x faster than nvm
- Auto-installs LTS on first shell startup
- Switch Node versions instantly: `fnm use <version>`

### Optimized Git Operations
- **Delta** - Syntax-highlighted diffs
- **SSH multiplexing** - 5x faster Git operations
- **Connection sharing** - Reuses SSH connections

### Modern CLI Replacements
All written in Rust for speed:
- `rg` (ripgrep) instead of grep
- `fd` instead of find
- `bat` instead of cat
- `eza` instead of ls
- `bottom` instead of top
- `zoxide` instead of cd

### Consistent Theming
Catppuccin Mocha theme across:
- Terminal (Ghostty)
- Shell prompt (Starship)
- Editor (Neovim, Cursor)
- CLI tools (bat, delta, fzf)

### Lazy Loading
- Zsh completions defer 300-400ms of startup time
- Plugins load on-demand

## 📖 Learn More

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [Zero to Nix](https://zero-to-nix.com/)
- [Catppuccin Theme](https://github.com/catppuccin/catppuccin)

## 🤝 Contributing

This is a personal configuration, but feel free to:
- Fork and adapt it for your needs
- Open issues for bugs
- Submit PRs for improvements

## 📝 License

MIT License - Use freely for personal or commercial projects.

---

**Maintenance**: This configuration is actively maintained and tested on macOS with Apple Silicon.
