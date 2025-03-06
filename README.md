# Tag Manager

A bash script for managing semantic versioning tags in Git repositories with package.json support. This tool helps automate version bumping, git tagging, and package.json updates following semantic versioning principles.

## Features

- **Interactive menu-driven interface**
- **Command-line argument support with optional project prefix** (e.g., `tag --minor xp` will create a tag `xp-v1.0.0`)
- **Semantic versioning support** (major.minor.patch/hotfix)
- **Automatic update of package.json and package-lock.json versions**
- **Version history viewing**
- **Git tag creation and management**
- **Input validation**
- **Colored terminal output for better visibility**

## Prerequisites

- Git
- Node.js (for package.json manipulation)
- Bash shell

## Installation

Run the following command in your terminal:

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

This launches an interactive menu where you can:
1. View the current version
2. View version history
3. Create a new tag (major, minor, patch, or hotfix)
4. Update package.json and package-lock.json

### Command Line Arguments

For direct version bumping, use one of these arguments:

```shell
tag --major            # Bump major version (X.0.0)
tag --minor            # Bump minor version (x.X.0)
tag --patch            # Bump patch version (x.x.X)
tag --hotfix           # Bump hotfix version (x.x.x.X)
tag --history          # View version history
```

#### Optional Project Prefix

You may also supply an optional project prefix as the last argument. This prefix is added before the version tag. For example:

```shell
tag --minor xp       # Creates a tag named "xp-v1.0.0"
```

## License

This script is available under the MIT License. See the [LICENSE](LICENSE) file for more information.
