#!/bin/bash

# Author: Bikal Shrestha
# Version: 1.0.0
# Description: A bash script for managing semantic versioning tags in Git repositories with package.json support.
#              Now supports an optional project prefix provided as the last argument (e.g. tag.sh --minor xp will create a tag xp-v1.0.0).
# Date: 2024-12-21

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to validate semantic version format
validate_version() {
    if [[ ! $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error: Version must be in format X.Y.Z${NC}"
        exit 1
    fi
}

# Function to check for unstaged changes
check_unstaged_changes() {
    if ! git diff-index --quiet HEAD --; then
        echo -e "${RED}Error: You have unstaged changes. Please commit or stash them first.${NC}"
        exit 1
    fi
}

# Function to get current version from package.json
get_current_version() {
    if [ -f "package.json" ]; then
        version=$(node -p "require('./package.json').version")
        echo "$version"
    else
        echo -e "${RED}Error: package.json not found${NC}"
        exit 1
    fi
}

# Function to update version in package.json and package-lock.json
update_package_json() {
    local new_version=$1
    if [ -f "package.json" ]; then
        # Create a temporary file for package.json
        tmp_file=$(mktemp)
        # Update version in package.json while preserving formatting
        node -e "
            const fs = require('fs');
            const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
            pkg.version = '$new_version';
            fs.writeFileSync('$tmp_file', JSON.stringify(pkg, null, 2) + '\n');
        "
        # Replace original file with updated version
        mv "$tmp_file" package.json
        echo -e "${GREEN}Updated package.json version to $new_version${NC}"

        # Update package-lock.json if it exists (silently)
        if [ -f "package-lock.json" ]; then
            tmp_lock_file=$(mktemp)
            node -e "
                const fs = require('fs');
                const pkgLock = JSON.parse(fs.readFileSync('package-lock.json', 'utf8'));
                pkgLock.version = '$new_version';
                
                if (pkgLock.packages) {
                    pkgLock.packages[''].version = '$new_version';
                } else if (pkgLock.dependencies) {
                    pkgLock.version = '$new_version';
                }
                
                fs.writeFileSync('$tmp_lock_file', JSON.stringify(pkgLock, null, 2) + '\n');
            "
            mv "$tmp_lock_file" package-lock.json
        fi
    else
        echo -e "${RED}Error: package.json not found${NC}"
        exit 1
    fi
}

# Function to preview new version
preview_version() {
    local tag_type=$1
    local current_version=$(get_current_version)
    local major minor patch hotfix
    
    IFS='.' read -r major minor patch hotfix <<< "$current_version"
    
    case $tag_type in
        "major")
            echo "$((major + 1)).0.0"
            ;;
        "minor")
            echo "${major}.$((minor + 1)).0"
            ;;
        "patch")
            echo "${major}.${minor}.$((patch + 1))"
            ;;
        "hotfix")
            if [ -z "$hotfix" ]; then
                echo "${major}.${minor}.${patch}.1"
            else
                echo "${major}.${minor}.${patch}.$((hotfix + 1))"
            fi
            ;;
    esac
}

# Function to check if tag exists.
# It accepts an optional project prefix as a second parameter.
check_tag_exists() {
    local new_version=$1
    local project_prefix=$2
    local tag_name="${project_prefix:+$project_prefix-}v$new_version"
    if git rev-parse "$tag_name" >/dev/null 2>&1; then
        echo -e "${RED}Error: Tag $tag_name already exists${NC}"
        exit 1
    fi
}

# Function to create a new tag and update package.json
# Accepts an optional third parameter "project_prefix".
create_tag() {
    local tag_type=$1
    local skip_confirm=${2:-false}
    local project_prefix=${3:-""}
    
    # Check for unstaged changes
    check_unstaged_changes
    
    local current_version=$(get_current_version)
    local new_version=$(preview_version "$tag_type")

    # Check if tag already exists (using project prefix if provided)
    check_tag_exists "$new_version" "$project_prefix"
    
    echo -e "${BLUE}Current version: ${GREEN}$current_version${NC}"
    echo -e "${BLUE}New version will be: ${GREEN}$new_version${NC}"
    
    if [ "$skip_confirm" != "true" ]; then
        read -p "Do you want to proceed? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}Operation cancelled${NC}"
            return 1
        fi
    fi
    
    # Update package.json and package-lock.json with only the numeric version
    update_package_json "$new_version"
    
    # Build the tag name (includes project prefix if provided)
    local tag_name="${project_prefix:+$project_prefix-}v$new_version"
    local commit_message="$tag_name"
    
    # Commit package.json and package-lock.json changes
    git add package.json
    if [ -f "package-lock.json" ]; then
        git add package-lock.json
    fi
    git commit -m "$commit_message"
    
    # Create git tag
    echo -e "${GREEN}Creating new $tag_type tag: $tag_name${NC}"
    git tag -a "$tag_name" -m "$commit_message"
    
    echo -e "${GREEN}✨ Version $tag_name has been created locally.${NC}"
    echo -e "${BLUE}To publish this version:${NC}"
    echo -e "${GREEN}1. Review your changes${NC}"
    echo -e "${GREEN}2. Run: git push origin master${NC}"
    echo -e "${GREEN}3. Run: git push origin $tag_name${NC}"
}

# Function to show version history
show_version_history() {
    echo -e "${BLUE}Version History (last 10 tags):${NC}"
    git tag -l --sort=-v:refname | head -n 10
    echo ""
}

# Function to display current version and menu (interactive mode)
show_menu() {
    local current_version=$(get_current_version)
    echo -e "${BLUE}Current version: ${GREEN}$current_version${NC}"
    echo -e "${BLUE}Select action:${NC}"
    echo ""
    echo -e "1) Major  (x.0.0)     - Breaking changes"
    echo -e "2) Minor  (0.x.0)     - New features"
    echo -e "3) Patch  (0.0.x)     - Bug fixes"
    echo -e "4) Hotfix (0.0.0.x)   - Quick fixes"
    echo -e "5) Show version history"
    echo -e "6) Exit"
    echo ""
}

# Function to handle user selection (interactive mode)
handle_selection() {
    local choice
    read -p "Enter your choice (1-6): " choice
    echo ""
    
    case $choice in
        1) create_tag "major" ;;
        2) create_tag "minor" ;;
        3) create_tag "patch" ;;
        4) create_tag "hotfix" ;;
        5) show_version_history ;;
        6) 
            echo -e "${BLUE}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please try again.${NC}"
            return 1
            ;;
    esac
}

# Function to handle command line arguments
# Now expects the ordering: flag [project_initial]
handle_arguments() {
    if [ "$#" -eq 1 ]; then
        # Only the flag is provided; no project initial
        local flag=$1
        case "$flag" in
            --major)
                create_tag "major" true ""
                ;;
            --minor)
                create_tag "minor" true ""
                ;;
            --patch)
                create_tag "patch" true ""
                ;;
            --hotfix)
                create_tag "hotfix" true ""
                ;;
            --history)
                show_version_history
                ;;
            --help|-h)
                echo "Usage: $0 [--major|--minor|--patch|--hotfix|--history|--help] [project_initial]"
                echo ""
                echo "Options:"
                echo "  --major          Bump major version (X.0.0)"
                echo "  --minor          Bump minor version (x.X.0)"
                echo "  --patch          Bump patch version (x.x.X)"
                echo "  --hotfix         Bump hotfix version (x.x.x.X)"
                echo "  --history        View version history"
                echo "  --help           Show this help message"
                echo "  project_initial  Optional project prefix for the git tag (provided as the last argument)"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid argument: $flag${NC}"
                echo "Use --help to see available options"
                exit 1
                ;;
        esac
    elif [ "$#" -eq 2 ]; then
        # The first argument is the flag and the second is the project initial
        local flag=$1
        local project_prefix=$2
        case "$flag" in
            --major)
                create_tag "major" true "$project_prefix"
                ;;
            --minor)
                create_tag "minor" true "$project_prefix"
                ;;
            --patch)
                create_tag "patch" true "$project_prefix"
                ;;
            --hotfix)
                create_tag "hotfix" true "$project_prefix"
                ;;
            --history)
                show_version_history
                ;;
            --help|-h)
                echo "Usage: $0 [--major|--minor|--patch|--hotfix|--history|--help] [project_initial]"
                echo ""
                echo "Options:"
                echo "  --major          Bump major version (X.0.0)"
                echo "  --minor          Bump minor version (x.X.0)"
                echo "  --patch          Bump patch version (x.x.X)"
                echo "  --hotfix         Bump hotfix version (x.x.x.X)"
                echo "  --history        View version history"
                echo "  --help           Show this help message"
                echo "  project_initial  Optional project prefix for the git tag (provided as the last argument)"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid flag: $flag${NC}"
                echo "Use --help to see available options"
                exit 1
                ;;
        esac
    else
        echo -e "${RED}Invalid arguments${NC}"
        echo "Usage: $0 [--major|--minor|--patch|--hotfix|--history|--help] [project_initial]"
        exit 1
    fi
}

# Check if current directory is a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not a git repository${NC}"
    exit 1
fi

# Main execution
if [ $# -eq 0 ]; then
    # Interactive mode
    clear  # Clear the screen for better presentation
    while true; do
        show_menu
        handle_selection
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
else
    # Command line argument mode
    handle_arguments "$@"
fi
