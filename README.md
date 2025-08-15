# macOS Developer Environment Bootstrap

A simple, idempotent script to set up a complete macOS developer environment on Apple Silicon Macs.

## Quick Start

```bash
git clone <this-repo>
cd macos-provisioning
./bootstrap.sh
```

## What It Installs

### CLI Tools
- **Git ecosystem**: git, gh (GitHub CLI)
- **Search & navigation**: fzf, ripgrep, fd, bat, eza
- **Development**: node, python@3.12, pnpm
- **Utilities**: wget, tmux, openssl@3, gnupg, direnv
- **Shell**: Fish shell with sensible defaults

### GUI Applications
- **Terminal**: iTerm2
- **Editor**: Visual Studio Code
- **Productivity**: Rectangle (window management), Raycast (launcher)
- **Media**: Spotify

### Fonts
- JetBrains Mono (programming font)

## Features

### Idempotent
Safe to run multiple times - checks for existing installations before attempting to install.

### Fish Shell Setup
- Sets Fish as your default shell
- Configures useful aliases (`ll`, `cat` → `bat`, `grep` → `rg`, etc.)
- Includes common Git aliases
- Adds Homebrew and pnpm to PATH

### Global Package Management
- Sets up `pipx` for Python CLI tools
- Installs `claude-code` globally via npm
- Configures PATH for global packages

### Environment Management
- Sets up direnv for project-specific environment variables
- Creates `.envrc` and `.envrc.local` templates
- Automatically loads environment variables in Fish shell

## Customization

### Adding More Packages
Edit `Brewfile` to add more CLI tools, GUI apps, or fonts:

```ruby
# Add a CLI tool
brew "your-tool"

# Add a GUI app
cask "your-app"

# Add a font
cask "font-your-font"
```

### Adding Global Packages
Edit the `setup_global_packages()` function in `bootstrap.sh`:

```bash
# For npm packages
npm install -g your-package

# For Python packages via pipx
pipx install your-python-tool
```

### Environment Variables
1. Edit `.envrc.local` to add your secrets and environment variables
2. Run `direnv allow` to enable automatic loading

### Fish Shell Config
Customize `~/.config/fish/config.fish` after running the bootstrap script.

## Requirements

- macOS (Apple Silicon)
- Internet connection
- Administrator privileges (for some installations)

## What Happens During Bootstrap

1. **Prerequisites**: Installs Xcode CLI tools and Rosetta 2
2. **Homebrew**: Installs and sets up package manager
3. **Packages**: Installs all tools and apps from Brewfile
4. **Shell**: Sets up Fish as default shell with configuration
5. **Environment**: Configures direnv for environment management
6. **Cleanup**: Creates .gitignore for common development files

## Post-Installation

After bootstrap completes:

1. **Restart your terminal** or run `exec fish`
2. **Add secrets** to `.envrc.local`
3. **Enable direnv** with `direnv allow`
4. **Customize** Fish config as needed

## Troubleshooting

### Xcode CLI Tools
If the script exits asking you to complete Xcode CLI tools installation, just re-run the script after the installation completes.

### Fish Shell
If Fish doesn't become your default shell, manually run:
```bash
chsh -s $(which fish)
```

### Homebrew PATH Issues
If commands aren't found after installation, ensure Homebrew is in your PATH:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## Security

- No secrets are stored in this repository
- Environment variables go in `.envrc.local` (git-ignored)
- Use direnv for automatic, secure environment loading