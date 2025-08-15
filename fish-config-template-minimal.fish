if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Created by `pipx` on 2024-02-18 18:56:35
set PATH $PATH $HOME/.local/bin

# API Configuration - Add your keys to ~/.config/fish/secrets.fish
# Example secrets.fish content:
# set -x AZURE_API_BASE "https://your-azure-endpoint.openai.azure.com/"
# set -x AZURE_API_VERSION "2024-07-01-preview"
# set -x OPENAI_API_TYPE "azure"
# set -x AZURE_OPENAI_ENDPOINT "https://your-azure-endpoint.openai.azure.com/"
# set -x OPENAI_API_AZURE_ENGINE "gpt-4o"
# set -x OPENAI_API_KEY "your-openai-api-key"
# set -x OPENAI_API_VERSION "2024-07-01-preview"

# Load secrets if they exist
if test -f ~/.config/fish/secrets.fish
    source ~/.config/fish/secrets.fish
end

# gpg
set -gx GPG_TTY (tty)

# .bin directory  
fish_add_path $HOME/.bin/balena-cli
fish_add_path $HOME/.bin            # For your custom scripts

# Basic utility functions
function kill_processes
    set force false
    if contains -- --force $argv
        set force true
        set -e argv[(contains -i -- --force $argv)]
    end
    
    if test (count $argv) -eq 0
        echo "Usage: killps [--force] <search_term>"
        return 1
    end
    
    set pids (ps aux | grep $argv[1] | gum choose --no-limit | awk '{print $2}')
    if test -n "$pids"
        if test $force = true
            echo $pids | xargs kill -9
        else
            echo $pids | xargs kill
        end
    end
end

function git_add_choose
    set files (git status --porcelain | gum choose --no-limit | awk '{print $2}' )
    if test -n "$files"
        echo $files | xargs git add
    end
end

# Basic aliases
alias psk="kill_processes" # kills processes matching a search term
alias pskf="kill_processes --force" # kills processes matching a search term and forcefully

# Basic git aliases
alias gs="git status" # shows the status of the repository
alias gst="git stash" # stashes the current changes
alias gaa="git add *" # adds all files to the staging area
alias gac="git_add_choose" # adds chosen files to the staging area
alias grh="git reset HEAD~1" # resets the last commit
alias gca="git commit --amend --no-edit" # amends the last commit
alias fwl="git push --force-with-lease" # pushes to origin with force-with-lease
alias gcm="git checkout main" # checks out main
alias gpr="git pull -r" # pulls from origin
alias gcmpr="gcm && gpr" # checks out main and pulls from origin
alias gcob="git checkout -b" # creates a new branch
alias gco="git checkout -" # checks out the previous branch
alias gcom="git checkout main" # checks out main
alias grom="git rebase origin/main" # rebase the current branch onto main
alias grm="gcom && gpr && gco && grom" # rebase main, checkout the branch, pull from origin, and rebase onto main
alias gpo="git push origin --set-upstream (git branch --show-current)" # pushes the current branch to origin

# Tool-specific aliases (uncomment if you have these tools)
#alias prs="gh pr list --limit 100 | cut -f1,2 | gum choose | cut -f1 | xargs gh pr checkout"
#alias prsf="gh pr list --limit 100 | cut -f1,2 | gum filter | cut -f1 | xargs gh pr checkout"
#alias gbd="git branch | grep -v 'main' | cut -c 3- | gum choose --no-limit | xargs git branch -D"
#alias pick_commit="git log --oneline | gum filter | cut -d' ' -f1 | pbcopy"

# Added by LM Studio CLI (lms)
set -gx PATH $PATH $HOME/.lmstudio/bin

# Android Studio–bundled JDK (uncomment if you use Android development)
#set -gx JAVA_HOME "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
#set -gx PATH $JAVA_HOME/bin $PATH

# Additional API Keys - Add these to ~/.config/fish/secrets.fish
# set -gx GROQ_API_KEY "your-groq-api-key"
# set -gx OPENROUTER_API_KEY "your-openrouter-api-key"
# set -gx GEMINI_API_KEY "your-gemini-api-key"
# set -gx OPENAI_API_KEY "your-openrouter-api-key" # via openrouter

# Default LM Studio settings (safe to keep)
set -gx LM_STUDIO_API_BASE "http://127.0.0.1:1234/v1"
set -gx LM_STUDIO_API_KEY "my-dummy-api-key"

# Model configurations
set -gx BIG_MODEL_NAME "google/gemini-2.5-pro-preview"
set -gx SMALL_MODEL_NAME "google/gemini-2.0-flash-lite-001"

set -gx LOG_LEVEL "INFO"

# ============================================================================
# ADVANCED FUNCTIONS (Uncomment if you install the required tools)
# ============================================================================

# Requires: llm, gum
#function autocommit
#    # [function code here]
#end
#alias gc=autocommit
#alias gcne="autocommit --no-edit"

# Requires: llm, gum
#function generate_changelog
#    # [function code here]
#end
#alias chg=generate_changelog
#alias changes="generate_changelog"

# Requires: files-to-prompt
#function f2p
#    # [function code here]  
#end

# Requires: tmux
#function tmux_run_all
#    # [function code here]
#end

# Requires: specific Python environment setup
#function pyenv_activate
#    # [function code here]
#end
#alias activate="pyenv_activate"
#alias act="activate"

# Media download aliases (uncomment if you install yt-dlp and yle-dl from Brewfile)
#alias ytdl="yt-dlp -o '~/Downloads/Youtube/%(title)s.%(ext)s'"
#alias yledl="yle-dl"

# Personal aliases (customize these)
#alias edit_fish_config="cursor -a ~/.config/fish/config.fish"