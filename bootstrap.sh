#!/bin/bash

set -e

echo "🍎 macOS Developer Environment Bootstrap"
echo "========================================"

check_command() {
    if command -v "$1" &> /dev/null; then
        echo "✅ $1 is already installed"
        return 0
    else
        echo "❌ $1 is not installed"
        return 1
    fi
}

install_xcode_cli_tools() {
    echo "📦 Checking Xcode Command Line Tools..."
    if xcode-select -p &> /dev/null; then
        echo "✅ Xcode Command Line Tools already installed"
    else
        echo "🔧 Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "⏳ Please complete the Xcode CLI tools installation and re-run this script"
        exit 1
    fi
}

install_rosetta() {
    echo "🔧 Checking Rosetta 2..."
    if [[ $(uname -m) == "arm64" ]]; then
        if /usr/bin/pgrep oahd >/dev/null 2>&1; then
            echo "✅ Rosetta 2 is already installed and running"
        else
            echo "🔧 Installing Rosetta 2..."
            /usr/sbin/softwareupdate --install-rosetta --agree-to-license
        fi
    else
        echo "ℹ️ Not on Apple Silicon, skipping Rosetta 2"
    fi
}

install_homebrew() {
    echo "🍺 Checking Homebrew..."
    if check_command "brew"; then
        echo "🔄 Updating Homebrew..."
        brew update
    else
        echo "🔧 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}

install_packages() {
    echo "📦 Installing packages from Brewfile..."
    if [[ -f "Brewfile" ]]; then
        brew bundle
    else
        echo "❌ Brewfile not found!"
        exit 1
    fi
}

setup_fish_shell() {
    echo "🐟 Setting up Fish shell..."
    
    # Check if fish is installed
    if ! check_command "fish"; then
        echo "❌ Fish shell not found. Make sure it's in your Brewfile."
        return 1
    fi
    
    # Get fish path
    FISH_PATH=$(which fish)
    
    # Add fish to allowed shells if not already there
    if ! grep -q "$FISH_PATH" /etc/shells; then
        echo "🔧 Adding Fish to allowed shells..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells
    fi
    
    # Set fish as default shell if not already
    if [[ "$SHELL" != "$FISH_PATH" ]]; then
        echo "🔧 Setting Fish as default shell..."
        chsh -s "$FISH_PATH"
        echo "ℹ️ Please restart your terminal or run 'exec fish' to use Fish shell"
    else
        echo "✅ Fish is already the default shell"
    fi
}

setup_fish_config() {
    echo "🐟 Setting up Fish configuration..."
    
    # Create fish config directory
    mkdir -p ~/.config/fish/conf.d
    
    # Basic Fish configuration
    cat > ~/.config/fish/config.fish << 'EOF'
# Basic Fish configuration
set -g fish_greeting ""

# Add common paths
set -gx PATH /opt/homebrew/bin $PATH
set -gx PATH /opt/homebrew/sbin $PATH

# Python pipx path
set -gx PATH ~/.local/bin $PATH

# Node.js paths
set -gx PATH ~/.local/share/pnpm $PATH

# Aliases
alias ll "ls -la"
alias la "ls -la"
alias cat "bat"
alias find "fd"
alias grep "rg"

# Git aliases
alias gs "git status"
alias ga "git add"
alias gc "git commit"
alias gp "git push"
alias gl "git log --oneline"

# Load direnv if available
if command -v direnv > /dev/null
    direnv hook fish | source
end
EOF

    echo "✅ Fish configuration created"
}

setup_global_packages() {
    echo "📦 Setting up global packages..."
    
    # Setup pipx if available
    if check_command "python3"; then
        echo "🐍 Setting up pipx for Python packages..."
        if ! check_command "pipx"; then
            python3 -m pip install --user pipx
            python3 -m pipx ensurepath
        fi
        
        # Add pipx to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # Install global npm packages
    if check_command "npm"; then
        echo "📦 Installing global npm packages..."
        
        # Check if claude-code is already installed
        if ! npm list -g claude-code &> /dev/null; then
            echo "🔧 Installing claude-code..."
            npm install -g claude-code
        else
            echo "✅ claude-code already installed"
        fi
        
        # Add other global packages here as needed
        # npm install -g @vercel/ncc
        # npm install -g typescript
    else
        echo "⚠️ npm not found, skipping global npm packages"
    fi
    
    echo "✅ Global packages setup complete"
}

setup_direnv() {
    echo "📁 Setting up direnv..."
    
    if check_command "direnv"; then
        # Create sample .envrc
        if [[ ! -f ".envrc" ]]; then
            cat > .envrc << 'EOF'
# Example environment variables
# export API_KEY="your-api-key"
# export DATABASE_URL="your-database-url"

# Load local overrides if they exist
# source_env_if_exists .envrc.local
EOF
            echo "📄 Created sample .envrc file"
        fi
        
        # Create .envrc.local template
        if [[ ! -f ".envrc.local" ]]; then
            cat > .envrc.local << 'EOF'
# Local environment variables (ignored by git)
# Add your secrets here
EOF
            echo "📄 Created .envrc.local template"
        fi
        
        echo "✅ direnv setup complete"
    else
        echo "⚠️ direnv not found in Brewfile, skipping direnv setup"
    fi
}

create_gitignore() {
    echo "📁 Setting up .gitignore..."
    
    if [[ ! -f ".gitignore" ]]; then
        cat > .gitignore << 'EOF'
# Environment variables
.envrc.local

# macOS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE
.vscode/
.idea/

# Node.js
node_modules/
npm-debug.log*

# Python
__pycache__/
*.pyc
.venv/
EOF
        echo "✅ .gitignore created"
    else
        echo "✅ .gitignore already exists"
    fi
}

main() {
    echo "🚀 Starting bootstrap process..."
    
    install_xcode_cli_tools
    install_rosetta
    install_homebrew
    install_packages
    setup_fish_shell
    setup_fish_config
    setup_global_packages
    setup_direnv
    create_gitignore
    
    echo ""
    echo "🎉 Bootstrap complete!"
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal or run 'exec fish'"
    echo "2. Edit .envrc.local to add your environment variables"
    echo "3. Run 'direnv allow' to enable environment loading"
    echo ""
    echo "Happy coding! 🚀"
}

main "$@"