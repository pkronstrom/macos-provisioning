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

safe_overwrite() {
    local file_path="$1"
    local description="$2"
    
    if [[ -f "$file_path" ]]; then
        echo "⚠️ Existing $description found at: $file_path"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "📋 Creating backup..."
            cp "$file_path" "${file_path}.backup.$(date +%Y%m%d_%H%M%S)"
            echo "✅ Backup created, proceeding with overwrite"
            return 0
        else
            echo "⏭️ Skipping $description setup"
            return 1
        fi
    fi
    
    return 0
}

install_xcode_cli_tools() {
    echo "📦 Checking Xcode Command Line Tools..."
    if xcode-select -p &> /dev/null; then
        echo "✅ Xcode Command Line Tools already installed"
        return 0
    fi
    
    echo "🔧 Installing Xcode Command Line Tools..."
    xcode-select --install 2>/dev/null || {
        echo "❌ Failed to trigger Xcode CLI tools installation"
        echo "Please install manually: xcode-select --install"
        return 1
    }
    
    echo "⏳ Waiting for Xcode CLI tools installation to complete..."
    echo "This may take several minutes..."
    
    # Wait for installation to complete with timeout
    local timeout=1800  # 30 minutes timeout
    local elapsed=0
    
    while ! xcode-select -p &> /dev/null; do
        if [[ $elapsed -ge $timeout ]]; then
            echo "❌ Xcode CLI tools installation timed out"
            echo "Please complete the installation manually and re-run this script"
            return 1
        fi
        
        sleep 10
        elapsed=$((elapsed + 10))
        
        # Show progress every minute
        if [[ $((elapsed % 60)) -eq 0 ]]; then
            echo "⏳ Still waiting... ($((elapsed / 60)) minutes elapsed)"
        fi
    done
    
    echo "✅ Xcode Command Line Tools installation complete"
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
        if ! brew update; then
            echo "⚠️ Failed to update Homebrew, continuing anyway"
        fi
    else
        echo "🔧 Installing Homebrew..."
        
        # Download and verify Homebrew installer
        local temp_script=$(mktemp)
        echo "📥 Downloading Homebrew installer..."
        
        if ! curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > "$temp_script"; then
            echo "❌ Failed to download Homebrew installer"
            rm -f "$temp_script"
            return 1
        fi
        
        # Basic validation - check if it looks like the expected script
        if ! grep -q "Homebrew" "$temp_script" || ! grep -q "install" "$temp_script"; then
            echo "❌ Downloaded script doesn't appear to be the Homebrew installer"
            rm -f "$temp_script"
            return 1
        fi
        
        echo "✅ Homebrew installer validated, proceeding with installation..."
        if ! /bin/bash "$temp_script"; then
            echo "❌ Homebrew installation failed"
            rm -f "$temp_script"
            return 1
        fi
        
        rm -f "$temp_script"
        
        # Add Homebrew to PATH for Apple Silicon
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        echo "✅ Homebrew installed successfully"
    fi
}

install_packages() {
    echo "📦 Installing packages from Brewfile..."
    if [[ -f "Brewfile" && -r "Brewfile" ]]; then
        # Basic validation of Brewfile
        if ! grep -q "^brew\|^cask\|^tap\|^#" "Brewfile"; then
            echo "❌ Brewfile appears to be invalid (no brew/cask/tap entries found)"
            return 1
        fi
        
        echo "✅ Brewfile validated, installing packages..."
        if brew bundle; then
            echo "✅ All packages installed successfully"
        else
            echo "⚠️ Some packages failed to install"
            echo "Check the output above for details"
            echo "You can run 'brew bundle' manually to retry"
        fi
    else
        echo "❌ Brewfile not found or not readable!"
        return 1
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
        if chsh -s "$FISH_PATH"; then
            echo "✅ Fish set as default shell"
            echo "ℹ️ Please restart your terminal or run 'exec fish' to use Fish shell"
        else
            echo "❌ Failed to change shell to Fish"
            echo "You may need to run 'chsh -s $FISH_PATH' manually"
            echo "Or add Fish to /etc/shells if it's missing"
        fi
    else
        echo "✅ Fish is already the default shell"
    fi
}

setup_fish_config() {
    echo "🐟 Setting up Fish configuration..."
    
    # Create fish config directory
    mkdir -p ~/.config/fish/conf.d
    
    # Check if we should overwrite existing config
    if ! safe_overwrite ~/.config/fish/config.fish "Fish configuration"; then
        return 0
    fi
    
    # Use template if available, otherwise fall back to basic config
    if [[ -f "fish-config-template.fish" ]]; then
        echo "📋 Using fish-config-template.fish..."
        cp fish-config-template.fish ~/.config/fish/config.fish
        echo "✅ Fish configuration created from template"
        
        # Create secrets template
        if [[ ! -f ~/.config/fish/secrets.fish ]]; then
            cat > ~/.config/fish/secrets.fish << 'EOF'
# Fish secrets file - Add your API keys and sensitive environment variables here
# This file should not be committed to git

# Example API keys (uncomment and fill in as needed):
# set -x OPENAI_API_KEY "your-openai-api-key"
# set -x GROQ_API_KEY "your-groq-api-key"
# set -x OPENROUTER_API_KEY "your-openrouter-api-key"
# set -x GEMINI_API_KEY "your-gemini-api-key"
# set -x AZURE_API_BASE "https://your-azure-endpoint.openai.azure.com/"
# set -x AZURE_API_VERSION "2024-07-01-preview"
EOF
            chmod 600 ~/.config/fish/secrets.fish  # Secure permissions
            echo "📄 Created secrets.fish template with secure permissions"
        fi
    else
        echo "⚠️ fish-config-template.fish not found, using basic configuration..."
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
alias ll "eza -la"
alias la "eza -la"
alias ls "eza"
alias cat "bat"
alias find "fd"
alias grep "rg"

# Git aliases
alias gs "git status"
alias ga "git add"
alias gc "git commit"
alias gp "git push"
alias gl "git log --oneline"

# Load direnv hook
if command -v direnv > /dev/null
    direnv hook fish | source
end
EOF
        echo "✅ Basic Fish configuration created"
    fi
}

setup_vim_config() {
    echo "📝 Setting up Vim configuration..."
    
    # Check if vim is installed
    if ! check_command "vim"; then
        echo "❌ Vim not found. Make sure it's in your Brewfile."
        return 1
    fi
    
    # Check if we should overwrite existing config
    if ! safe_overwrite ~/.vimrc "Vim configuration"; then
        return 0
    fi
    
    # Use template if available, otherwise fall back to basic config
    if [[ -f "vim-config-template.vim" ]]; then
        echo "📋 Using vim-config-template.vim..."
        cp vim-config-template.vim ~/.vimrc
        echo "✅ Vim configuration created from template"
        
        # Install Vundle if not already installed
        if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
            echo "📦 Installing Vundle plugin manager..."
            if git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim; then
                echo "✅ Vundle installed"
            else
                echo "❌ Failed to install Vundle"
                echo "Please install manually: git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim"
                return 1
            fi
        else
            echo "✅ Vundle already installed"
        fi
        
        # Install plugins with timeout
        echo "📦 Installing Vim plugins..."
        if timeout 300 vim +PluginInstall +qall; then
            echo "✅ Vim plugins installed"
        else
            echo "⚠️ Vim plugin installation timed out or failed"
            echo "You can run 'vim +PluginInstall +qall' manually later"
        fi
        
    else
        echo "⚠️ vim-config-template.vim not found, using basic configuration..."
        # Basic Vim configuration
        cat > ~/.vimrc << 'EOF'
set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'morhetz/gruvbox'

call vundle#end()
filetype plugin indent on

syntax on
colorscheme gruvbox
set number
set expandtab
set tabstop=4
set shiftwidth=4
EOF
        echo "✅ Basic Vim configuration created"
        
        # Install Vundle and plugins for basic config too
        if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
            echo "📦 Installing Vundle plugin manager..."
            git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
        fi
        
        echo "📦 Installing Vim plugins..."
        if timeout 300 vim +PluginInstall +qall; then
            echo "✅ Basic Vim setup complete"
        else
            echo "⚠️ Vim plugin installation timed out or failed"
            echo "You can run 'vim +PluginInstall +qall' manually later"
        fi
    fi
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

# Fish secrets
secrets.fish

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
    setup_vim_config
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