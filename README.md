# Tag Manager

A Bash script designed to manage semantic versioning tags in Git repositories, complete with package.json support. This tool automates version increments, Git tagging, and updates to package.json, adhering to semantic versioning standards.

## Features

-   Interactive menu-driven interface
-   Command-line argument support
-   Semantic versioning support (major.minor.patch.hotfix)
-   Automatic package.json version updating
-   Version history viewing
-   Git tag creation and management
-   Input validation
-   Colored terminal output for better visibility

## Prerequisites

-   Git
-   Node.js (for package.json manipulation)
-   Bash shell

## Installation

Run this command on terminal.

```shell
sudo curl https://raw.githubusercontent.com/bikal1000/tag-manager/main/tag -o /usr/local/bin/tag && sudo chmod +x /usr/local/bin/tag
```

## Usage

You can run the script in two ways:

### Interactive Mode

Simply run the command without any arguments:

```shell
tag
```

This will launch an interactive menu where you can:

1. View current version
2. View version history
3. Create a new tag (major, minor, patch, or hotfix)
4. Update package.json version

### Command Line Arguments

For direct version bumping, use one of these arguments:

```shell
tag --major    # Bump major version (X.0.0)
tag --minor    # Bump minor version (x.X.0)
tag --patch    # Bump patch version (x.x.X)
tag --hotfix   # Bump hotfix version (x.x.x.X)
tag --history  # View version history
```

## License

This script is available under the MIT License. See the LICENSE file for more information.
