#!/bin/bash

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

# Function to update version in package.json
update_package_json() {
    local new_version=$1
    if [ -f "package.json" ]; then
        # Create a temporary file
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

# Function to create a new tag and update package.json
create_tag() {
    local tag_type=$1
    local current_version=$(get_current_version)
    local new_version=$(preview_version "$tag_type")
    
    echo -e "${BLUE}Current version: ${GREEN}$current_version${NC}"
    echo -e "${BLUE}New version will be: ${GREEN}$new_version${NC}"
    
    read -p "Do you want to proceed? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Operation cancelled${NC}"
        return 1
    fi
    
    # Update package.json
    update_package_json "$new_version"
    
    # Create commit message
    local commit_message="v$new_version"
    
    # Commit package.json changes
    git add package.json
    git commit -m "$commit_message"
    
    # Create git tag
    echo -e "${GREEN}Creating new $tag_type tag: $new_version${NC}"
    git tag -a "v$new_version" -m "$commit_message"
    
    echo -e "${GREEN}✨ Version v$new_version has been created locally.${NC}"
    echo -e "${BLUE}To publish this version:${NC}"
    echo -e "${GREEN}1. Review your changes${NC}"
    echo -e "${GREEN}3. Run: git push origin v$new_version${NC}"
    echo -e "${GREEN}2. Run: git push origin master${NC}"
    
    # Exit the script after successful completion
    exit 0
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

# Handle command line arguments if provided
if [ $# -eq 1 ]; then
    case $1 in
        "major"|"minor"|"patch"|"hotfix")
            create_tag "$1"
            exit 0
            ;;
        "--help"|"-h")
            echo "Usage: $0 [major|minor|patch|hotfix]"
            echo "If no argument is provided, interactive menu will be shown."
            exit 0
            ;;
    esac
fi

# Main script
clear  # Clear the screen for better presentation

# Check if current directory is a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not a git repository${NC}"
    exit 1
fi

while true; do
    show_menu
    handle_selection
    echo ""
    read -p "Press Enter to continue..."
    clear
done