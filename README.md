# 🏷️ Tag Manager

A **cross-platform** CLI tool for managing semantic versioning tags in Git repositories with `package.json` support.

Works on **Windows**, **macOS**, and **Linux** — anywhere Node.js runs.

## Features

- 🎯 **Interactive mode** — menu-driven interface for quick tagging
- ⚡ **Command-line mode** — direct version bumping via subcommands
- 📦 **Semantic versioning** — `major`, `minor`, `patch`, and `hotfix` bumps
- 🏗️ **Project prefix** — optional prefix for monorepo/multi-project tags (e.g., `xp-v1.2.0`)
- 📝 **Auto-updates** `package.json` and `package-lock.json`
- 🔖 **Git tag creation** — annotated tags with automatic commit
- 📜 **Version history** — view recent tags at a glance
- ✅ **Safety checks** — validates clean working tree and prevents duplicate tags
- 🎨 **Colored output** — clear, readable terminal output

## Prerequisites

- [Node.js](https://nodejs.org/) >= 16
- [Git](https://git-scm.com/)

### Global install

```bash
npm install -g @bikal404/tag-manager
```

## Usage

### Interactive Mode

Run without any arguments to launch the interactive menu:

```bash
tag
```

You'll see a menu like:

```
──────────────────────────────────────────────────
  🏷️  Tag Manager
──────────────────────────────────────────────────

Current version: 1.2.3

? Select an action:
  ❯ Major  (X.0.0)     — Breaking changes
    Minor  (x.X.0)     — New features
    Patch  (x.x.X)     — Bug fixes
    Hotfix (x.x.x.X)   — Quick fixes
    ──────────────
    View version history
    Exit
```

### Command-Line Mode

For direct version bumping, use subcommands:

```bash
tag major           # Bump major version (X.0.0)
tag minor           # Bump minor version (x.X.0)
tag patch           # Bump patch version (x.x.X)
tag hotfix          # Bump hotfix version (x.x.x.X)
tag history         # View recent version history
```

### Project Prefix

Add an optional project prefix to scope tags for monorepos:

```bash
tag minor xp        # Creates tag: xp-v1.1.0
tag patch api       # Creates tag: api-v1.0.1
```

### Help

```bash
tag --help
tag minor --help
```

## How It Works

1. Reads the current version from `package.json`
2. Calculates the next version based on bump type
3. Updates `package.json` (and `package-lock.json` if present)
4. Commits the version change
5. Creates an annotated git tag
6. Prints push instructions

## Migrating from v1 (Bash)

If you were using the original bash script, the CLI arguments have changed slightly:

| Bash (v1)         | Node.js (v2)    |
| ----------------- | --------------- |
| `tag --major`     | `tag major`     |
| `tag --minor`     | `tag minor`     |
| `tag --minor xp`  | `tag minor xp`  |
| `tag --history`   | `tag history`   |
| `tag` (no args)   | `tag` (no args) |

## License

[MIT](LICENSE)
