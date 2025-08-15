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

# functions
function r
    $HOME/Projects/almaco/hotel-management-platform/run.sh
end

function autocommit
    # Parse flags
    set no_edit false
    for arg in $argv
        switch $arg
            case -n --no-edit
                set no_edit true
                break
        end
    end

    # Check if there are staged changes
    set diff_output (git diff --staged)
    if test -z "$diff_output"
        echo "No staged changes found. Use 'git add' to stage changes first."
        return 1
    end

    set llm_prompt "Generate a Git commit message with a short, concise title (under 50 chars), followed by a blank line, and then a short description of the changes in bullets (wrap lines to 72 chars). No descriptors likea Feat: or Fix:, Text only, no markdown."

    set temp_file (mktemp)
    git diff --staged | gum spin --spinner dot --title "Generating commit message..." --show-output -- llm "$llm_prompt" > $temp_file

    if test $no_edit = true
        git commit -F $temp_file
    else
        git commit -e -F $temp_file
    end
    set commit_status $status

    rm $temp_file
    return $commit_status
end

function generate_changelog
    if test (count $argv) -eq 0
        gum spin --spinner dot --title "Fetching updates from main..." -- sh -c 'git fetch origin main > /dev/null 2>&1'
        set base_commit origin/main
    else
        # Fetch PR if it starts with 'pr/' or '#'
        if string match -q 'pr/*' $argv[1]; or string match -q '#*' $argv[1]
            set pr_num (string replace -r '^(pr/|#)' '' $argv[1])
            gum spin --spinner dot --title "Fetching PR #$pr_num..." -- sh -c "git fetch origin pull/$pr_num/head:pr-$pr_num > /dev/null 2>&1"
            set base_commit "pr-$pr_num"
        else
            set base_commit $argv[1]
        end
    end

    set diff_output (git diff $base_commit..)

    if test -z "$diff_output"
        echo "No changes found between the current branch and $base_commit."
        return
    end

    set temp_file (mktemp)
    gum spin --spinner dot --title "Generating changelog..." --show-output -- sh -c "git diff $base_commit.. | llm 'Generate a description to summarize the changes in this diff in markdown format.'" > $temp_file
    
    gum format --type markdown < $temp_file
    
    rm $temp_file
end

function tmux_run_all
    if test (count $argv) -eq 0
        echo "Usage: tmux_run_all <command>"
        return 1
    end
    set cmd (string join " " $argv)
    set panes (tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}")
    for pane in $panes
        tmux send-keys -t $pane "$cmd" Enter
    end
end

function tmux_run_window
    if test (count $argv) -eq 0
        echo "Usage: tmux_run_window <command>"
        return 1
    end
    set cmd (string join " " $argv)
    set panes (tmux list-panes -F "#{session_name}:#{window_index}.#{pane_index}")
    set current_window (tmux display-message -p "#{session_name}:#{window_index}")
    for pane in $panes
        if string match -q "$current_window.*" $pane
            tmux send-keys -t $pane "$cmd" Enter
        end
    end
end

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

function pyenv_activate
    set pyenv_dir "$HOME/.pyenv"
    if not test -d $pyenv_dir
        echo "Pyenv directory not found at $pyenv_dir"
        return 1
    end

    set selected_env (ls $pyenv_dir | gum choose)
    if test -n "$selected_env"
        source $pyenv_dir/$selected_env/bin/activate.fish
    end
end

function choose_default_model
    set current_model (llm models | grep ">" | cut -d' ' -f2-)
    set selected_model (llm models | awk '!seen[$0]++' | sed 's/^> //' | awk '!/:$/' | gum choose --selected="$current_model")
    if test -n "$selected_model"
        # Extract just the model name after the colon and space
        set model_name (echo $selected_model | sed 's/.*: //')
        llm models default $model_name
        echo "Switched to model: $selected_model"
    end
end

function git_add_choose
    set files (git status --porcelain | gum choose --no-limit | awk '{print $2}' )
    if test -n "$files"
        echo $files | xargs git add
    end
end

 # files-to-prompt
function f2p
    if test (count $argv) -eq 0
        files-to-prompt . --cxml --ignore node_modules --ignore __pycache__ -o prompt.xml
    else
        files-to-prompt $argv --cxml --ignore node_modules --ignore __pycache__ -o prompt.xml
    end
    cat prompt.xml | pbcopy
    echo "Saved to prompt.xml, copied to clipboard"
end

 # commit-diff-to-prompt
 # --full: diffs the full file, otherwise diffs the changes
function c2p
    set output_file ""
    set commit_hash ""
    set full_file false
    set against_main false
    # Hardcoded list of files to ignore
    set ignore_files package-lock.json
    
    # Build exclude args
    set exclude_args
    for file in $ignore_files
        set exclude_args $exclude_args ":(exclude)$file"
    end
    
    # Parse arguments
    set i 1
    while test $i -le (count $argv)
        if test "$argv[$i]" = "--output" -o "$argv[$i]" = "-o"
            if test (math $i + 1) -le (count $argv)
                set output_file $argv[(math $i + 1)]
                set i (math $i + 2)
            else
                set i (math $i + 1)
            end
        else if test "$argv[$i]" = "--full" -o "$argv[$i]" = "-f"
            set full_file true
            set i (math $i + 1)
        else if test "$argv[$i]" = "--main" -o "$argv[$i]" = "-m"
            set against_main true
            set i (math $i + 1)
        else
            set commit_hash $argv[$i]
            set i (math $i + 1)
        end
    end
    
    # If no commit hash provided, show usage
    if test -z "$commit_hash"
        echo "Usage: c2p <commit_hash> [--output file.txt] [--full-file] [--main]"
        return 1
    end
    
    # Set diff target
    if test $against_main = true
        set diff_target main
    else
        set diff_target HEAD
    end
    
    # Get diff and copy to clipboard
    if test $full_file = true
        git diff --no-prefix $commit_hash..$diff_target $exclude_args | pbcopy
        echo "Full file diff from $commit_hash to $diff_target copied to clipboard (excluding $ignore_files)"
        
        # Save to file if requested
        if test -n "$output_file"
            git diff --no-prefix $commit_hash..$diff_target $exclude_args > $output_file
            echo "Full file diff saved to $output_file (excluding $ignore_files)"
        end
    else
        git diff $commit_hash..$diff_target $exclude_args | pbcopy
        echo "Diff from $commit_hash to $diff_target copied to clipboard (excluding $ignore_files)"
        
        # Save to file if requested
        if test -n "$output_file"
            git diff $commit_hash..$diff_target $exclude_args > $output_file
            echo "Diff saved to $output_file (excluding $ignore_files)"
        end
    end
end

# general aliases
alias cmd="llm cmd"
alias cdm="choose_default_model" # chooses a default model

alias ytdl="yt-dlp -o '~/Downloads/Youtube/%(title)s.%(ext)s'"
alias yledl="yle-dl"

alias psk="kill_processes" # kills processes matching a search term
alias pskf="kill_processes --force" # kills processes matching a search term and forcefully

alias activate="pyenv_activate" # activates a python environment
alias act="activate"

alias edit_fish_config="cursor -a ~/.config/fish/config.fish" # opens the fish config in cursor

# aliases for git
alias gc=autocommit # commits staged 
alias gcne="autocommit --no-edit" # commits staged without editing the commit message
alias grh="git reset HEAD~1" # resets the last commit
alias gs="git status" # shows the status of the repository
alias gst="git stash" # stashes the current changes
alias gaa="git add *" # adds all files to the staging area
alias gac="git_add_choose" # adds chosen files to the staging area
alias gacc="gac && gc" # adds chosen files and commits them
alias gpo="git push origin --set-upstream (git branch --show-current)" # pushes the current branch to origin
alias gca="git commit --amend --no-edit" # amends the last commit
alias fwl="git push --force-with-lease" # pushes to origin with force-with-lease
alias gcm="git checkout main" # checks out main
alias gpr="git pull -r" # pulls from origin
alias gcmpr="gcm && gpr" # checks out main and pulls from origin

alias prs="gh pr list --limit 100 | cut -f1,2 | gum choose | cut -f1 | xargs gh pr checkout" # checks out a chosen PR
alias prsf="gh pr list --limit 100 | cut -f1,2 | gum filter | cut -f1 | xargs gh pr checkout" # checks out a chosen PR

alias gbd="git branch | grep -v 'main' | cut -c 3- | gum choose --no-limit | xargs git branch -D" # deletes chosen branches

alias pick_commit="git log --oneline | gum filter | cut -d' ' -f1 | pbcopy" # picks a commit hash and copies it to clipboard

alias chg=generate_changelog # generates a changelog against main

alias gcob="git checkout -b" # creates a new branch
alias gco="git checkout -" # checks out the previous branch
alias gcom="git checkout main" # checks out main
alias grom="git rebase origin/main" # rebase the current branch onto main

alias grm="gcom && gpr && gco && grom" # rebase main, checkout the branch, pull from origin, and rebase onto main

alias changes="generate_changelog"

alias cxo="codex --provider openrouter --model openai/gpt-4o-mini"
alias cxogp="codex --provider openrouter --model google/gemini-2.5-pro-exp-03-25"
alias cxogf="codex --provider openrouter --model google/gemini-2.0-flash-lite-001"

alias cxg="codex --provider groq --model meta-llama/llama-4-maverick-17b-128e-instruct"
# deepseek-r1-distill-qwen-32b
# qwen-qwq-32b

alias cc="$HOME/.bin/custom/claude-code.sh"

alias tm="task-master"

# Added by LM Studio CLI (lms)
set -gx PATH $PATH $HOME/.lmstudio/bin

# Android Studio–bundled JDK
set -gx JAVA_HOME "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
set -gx PATH $JAVA_HOME/bin $PATH

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