#!/bin/bash

# Author: Bikal Shrestha
# Version: 1.0.0
# Description: A bash script for managing semantic versioning tags in Git repositories with package.json support.
# Date: 2024-12-21

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
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
            const package = JSON.parse(fs.readFileSync('package.json', 'utf8'));
            package.version = '$new_version';
            fs.writeFileSync('$tmp_file', JSON.stringify(package, null, 2) + '\n');
        "
        # Replace original file with updated version
        mv "$tmp_file" package.json
        echo -e "${GREEN}Updated package.json version to $new_version${NC}"

        # Update package-lock.json if it exists (silently)
        if [ -f "package-lock.json" ]; then
            tmp_lock_file=$(mktemp)
            node -e "
                const fs = require('fs');
                const packageLock = JSON.parse(fs.readFileSync('package-lock.json', 'utf8'));
                packageLock.version = '$new_version';
                packageLock.packages[''].version = '$new_version';
                fs.writeFileSync('$tmp_lock_file', JSON.stringify(packageLock, null, 2) + '\n');
            "
            mv "$tmp_lock_file" package-lock.json
        fi
    else
        echo -e "${RED}Error: package.json not found${NC}"
        exit 1
    fi
}

# Function to parse commits since last tag
parse_commits() {
    # Get the last tag
    local last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    # Get all commits since last tag
    git log --pretty=format:"%s" "$last_tag..HEAD" |
    while IFS= read -r line; do
        if [[ $line =~ ^(Add|Change|Deprecate|Remove|Fix)\([a-zA-Z0-9_-]+\): ]]; then
            echo "$line"
        fi
    done
}

# Function to generate changelog content
generate_changelog_content() {
    local new_version=$1
    local date=$(date +%Y-%m-%d)
    
    echo "## [$new_version] - $date"
    echo
    
    # Initialize category arrays
    declare -A categories=(
        ["Add"]=""
        ["Change"]=""
        ["Deprecate"]=""
        ["Remove"]=""
        ["Fix"]=""
    )
    
    # Store commits in array
    mapfile -t commits < <(parse_commits)
    
    # Categorize each commit
    for commit in "${commits[@]}"; do
        if [[ $commit =~ ^Add ]]; then
            categories["Add"]+="- ${commit}\n"
        elif [[ $commit =~ ^Change ]]; then
            categories["Change"]+="- ${commit}\n"
        elif [[ $commit =~ ^Deprecate ]]; then
            categories["Deprecate"]+="- ${commit}\n"
        elif [[ $commit =~ ^Remove ]]; then
            categories["Remove"]+="- ${commit}\n"
        elif [[ $commit =~ ^Fix ]]; then
            categories["Fix"]+="- ${commit}\n"
        fi
    done
    
    # Output categorized changes
    for category in "Add" "Change" "Deprecate" "Remove" "Fix"; do
        if [ -n "${categories[$category]}" ]; then
            echo "### $category"
            echo -e "${categories[$category]}"
            echo
        fi
    done
}

# Function to update CHANGELOG.md
update_changelog() {
    local new_version=$1
    local temp_file=$(mktemp)
    local changelog_file="CHANGELOG.md"
    
    # Create changelog if it doesn't exist
    if [ ! -f "$changelog_file" ]; then
        echo "# Changelog" > "$changelog_file"
        echo "" >> "$changelog_file"
        echo "All notable changes to this project will be documented in this file." >> "$changelog_file"
        echo "" >> "$changelog_file"
    fi
    
    # Generate new changelog content
    local new_content=$(generate_changelog_content "$new_version")
    
    if [ -n "$new_content" ]; then
        # Preserve header (first 4 lines)
        head -n 4 "$changelog_file" > "$temp_file"
        echo "" >> "$temp_file"
        
        # Add new changes
        echo "$new_content" >> "$temp_file"
        echo "" >> "$temp_file"
        
        # Add previous changes (skip header)
        tail -n +5 "$changelog_file" >> "$temp_file"
        
        # Replace original file
        mv "$temp_file" "$changelog_file"
        echo -e "${GREEN}Updated CHANGELOG.md${NC}"
        return 0
    else
        echo -e "${YELLOW}No matching commits found to update CHANGELOG.md${NC}"
        return 1
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

# Function to check if tag exists
check_tag_exists() {
    local new_version=$1
    if git rev-parse "v$new_version" >/dev/null 2>&1; then
        echo -e "${RED}Error: Tag v$new_version already exists${NC}"
        exit 1
    fi
}

# Function to create a new tag and update package.json
create_tag() {
    local tag_type=$1
    local skip_confirm=${2:-false}  # Optional parameter to skip confirmation
    
    # Check for unstaged changes
    check_unstaged_changes
    
    local current_version=$(get_current_version)
    local new_version=$(preview_version "$tag_type")
    
    # Check if tag already exists
    check_tag_exists "$new_version"
    
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
    
    # Update package.json and package-lock.json
    update_package_json "$new_version"
    
    # Update changelog
    update_changelog "$new_version"
    
    # Create commit message
    local commit_message="v$new_version"
    
    # Commit all changes
    git add package.json
    if [ -f "package-lock.json" ]; then
        git add package-lock.json
    fi
    if [ -f "CHANGELOG.md" ]; then
        git add CHANGELOG.md
    fi
    git commit -m "$commit_message"
    
    # Create git tag
    echo -e "${GREEN}Creating new $tag_type tag: $new_version${NC}"
    git tag -a "v$new_version" -m "$commit_message"
    
    echo -e "${GREEN}✨ Version v$new_version has been created locally.${NC}"
    echo -e "${BLUE}To publish this version:${NC}"
    echo -e "${GREEN}1. Review your changes${NC}"
    echo -e "${GREEN}2. Run: git push origin master${NC}"
    echo -e "${GREEN}3. Run: git push origin v$new_version${NC}"
}

# Function to show version history
show_version_history() {
    echo -e "${BLUE}Version History (last 10 tags):${NC}"
    git tag -l --sort=-v:refname | head -n 10
    echo ""
}

# Function to display current version and menu
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

# Function to handle user selection
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
handle_arguments() {
    case "$1" in
        --major)
            create_tag "major" true
            ;;
        --minor)
            create_tag "minor" true
            ;;
        --patch)
            create_tag "patch" true
            ;;
        --hotfix)
            create_tag "hotfix" true
            ;;
        --history)
            show_version_history
            ;;
        --help|-h)
            echo "Usage: $0 [--major|--minor|--patch|--hotfix|--history|--help]"
            echo ""
            echo "Options:"
            echo "  --major    Bump major version (X.0.0)"
            echo "  --minor    Bump minor version (x.X.0)"
            echo "  --patch    Bump patch version (x.x.X)"
            echo "  --hotfix   Bump hotfix version (x.x.x.X)"
            echo "  --history  View version history"
            echo "  --help     Show this help message"
            echo ""
            echo "If no argument is provided, interactive menu will be shown."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid argument: $1${NC}"
            echo "Use --help to see available options"
            exit 1
            ;;
    esac
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
    handle_arguments "$1"
fi
