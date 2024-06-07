#!/bin/bash

# Function to get the latest release version and download URL from GitHub API
get_latest_release_info() {
    local repo="$1"
    local release_json=$(curl -s "https://api.github.com/repos/$repo/releases/latest")

    # Extract the latest release version
    latest_version=$(echo "$release_json" | grep -o '"tag_name": *"[^"]*"' | sed 's/"tag_name": "//;s/"$//')

    # Extract the download URL of the zip file
    latest_download_url=$(echo "$release_json" | grep -o '"browser_download_url": *"[^"]*"' | sed 's/"browser_download_url": "//;s/"$//')

    if [ -z "$latest_version" ] || [ -z "$latest_download_url" ]; then
        echo "Failed to retrieve latest release information."
        exit 1
    fi
}

# Function to check if portable_mode file exists and contains version information
check_portable_mode() {
    if [ -f "portable_mode" ]; then
        local version=$(grep -oE '^Version:[[:space:]]*[0-9.]+[a-zA-Z0-9]*' portable_mode | cut -d ':' -f 2 | tr -d '[:space:]')
        if [ -n "$version" ]; then
            echo "$version"
        fi
    fi
}

# Function to prompt user for reinstallation
prompt_for_reinstall() {
    local installed_version="$1"

    reinstall="N"
    if [ -n "$PROMPT" ]; then
        read -p "You already have the latest version installed ($installed_version). Are you sure you want to reinstall? [y/N]: " reinstall
    fi
    if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
        return 1 # indicate failure
    fi
    return 0 # indicate success
}

# Function to download and extract the latest release zip file
download_and_extract_latest_release() {
    local file_name=$(basename "$latest_download_url")

    echo "Downloading latest release from: $latest_download_url"
    curl -L -o "$file_name" "$latest_download_url" || {
        echo "Failed to download the latest release."
        exit 1
    }

    local temp_dir=$(mktemp -d)
    echo "Extracting the downloaded zip file to: $temp_dir"

    unzip -qd "$temp_dir" "$file_name" || {
        echo "Failed to extract the downloaded zip file."
        exit 1
    }

    rm -rf bin data obs-plugins

    mv "$temp_dir"/* .

    rm -r "$temp_dir"
    rm "$file_name"

    echo "Latest release $latest_version has been downloaded and extracted"

    # Store the latest version back into portable_mode file
    echo "Version: $latest_version" > portable_mode
}

#--- flags

PROMPT=

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--prompt) PROMPT=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

#--- OS

WIN=false
case "$OSTYPE" in
    cygin*|msys*)
    WIN=true
    ;;
esac

# Check if current directory is $HOME
if [ "$WIN" = false -a "$(pwd)" = "$HOME" ]; then
    echo "Current directory is your home directory."
    mkdir -p obs-studio-portable
    cd obs-studio-portable || exit
    echo "Created and switched to 'obs-studio-portable' directory."
fi

#--- OBS Release Binary

# Specify the GitHub repository
repository="devxfamily-fork/obs-studio"

# Call the function to get the latest release information
get_latest_release_info "$repository"

# Check if portable_mode file exists and contains version information
installed_version=$(check_portable_mode)

should_download=true

# Check if the 'bin' folder exists in the current directory and if installed version matches the latest version
if [ -d "bin" ] && [ "$installed_version" ] && [ "$installed_version" == "$latest_version" ]; then
    prompt_for_reinstall "$installed_version" || should_download=false
fi

if [ "$should_download" == true ]; then
    # Call the function to download and extract the latest release zip file
    download_and_extract_latest_release
fi

#--- OBS Global ini

obs_global_ini="./config/obs-studio/global.ini"

# Check if the file exists
if [ -f "$obs_global_ini" ]; then
    # Check if the file contains the line JsonPretty=false
    if grep -q "^JsonPretty=false$" "$obs_global_ini"; then
        echo "Detected JsonPretty=false in global.ini."
        change="Y"
        if [ -n "$PROMPT" ]; then
            read -p "Do you want to change it back to JsonPretty=true? [Y/n]: " change
        fi
        if [[ ! "$change" =~ ^[Nn]$ ]]; then
            # Use sed to replace JsonPretty=false with JsonPretty=true
            sed -i 's/^JsonPretty=false$/JsonPretty=true/' "$obs_global_ini"
            echo "Changed JsonPretty=false to JsonPretty=true."
        fi
    fi
else
    # Create the directory if it doesn't exist
    mkdir -p "$(dirname "$obs_global_ini")"
    
    # Write the desired content to the file
    echo -e "[General]\nJsonPretty=true" > "$obs_global_ini"
    echo "Content added to global.ini."
fi

#--- Git

if [ ! -d ".git" ]; then
    git_init="Y"
    if [ -n "$PROMPT" ]; then
        read -p "This folder is not a git repository. Do you want to initialize it? [Y/n]: " git_init
    fi
    if [[ ! "$git_init" =~ ^[Nn]$ ]]; then
        git init
        echo "Git repository initialized."
    else
        exit 0
    fi
fi

# Check if .gitignore exists
if [ ! -f ".gitignore" ]; then
    echo "Downloading .gitignore file..."
    curl -sSfL -o .gitignore "https://raw.githubusercontent.com/devxfamily/obs-studio-portable/main/.gitignore"
    echo ".gitignore file downloaded."
fi