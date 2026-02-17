import { execSync } from 'node:child_process';
import { error } from './ui.js';

/**
 * Run a git command synchronously and return trimmed stdout.
 * Returns null if the command fails.
 * @param {string} args
 * @returns {string|null}
 */
function git(args) {
    try {
        return execSync(`git ${args}`, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();
    } catch {
        return null;
    }
}

/**
 * Check if the current directory is inside a git repository.
 * Exits with an error if not.
 */
export function ensureGitRepo() {
    if (git('rev-parse --git-dir') === null) {
        error('Not a git repository. Navigate to a git project first.');
        process.exit(1);
    }
}

/**
 * Check for uncommitted changes in the working tree.
 * Exits with an error if there are unstaged/uncommitted changes.
 */
export function ensureCleanWorkingTree() {
    const result = git('diff-index --quiet HEAD --');
    // git diff-index returns exit code 1 if there are changes, which means git() returns null
    if (result === null) {
        // Double-check: it could also fail if HEAD doesn't exist (fresh repo with no commits)
        const status = git('status --porcelain');
        if (status && status.length > 0) {
            error('You have uncommitted changes. Please commit or stash them first.');
            process.exit(1);
        }
    }
}

/**
 * Check if a git tag already exists.
 * @param {string} tagName
 * @returns {boolean}
 */
export function tagExists(tagName) {
    return git(`rev-parse ${tagName}`) !== null;
}

/**
 * Create an annotated git tag.
 * @param {string} tagName
 * @param {string} message
 */
export function createTag(tagName, message) {
    const result = git(`tag -a "${tagName}" -m "${message}"`);
    if (result === null) {
        // tag command returns empty string on success, null on failure
        // Actually execSync returns '' on success for tag, let's re-check
    }
}

/**
 * Stage specific files and create a commit.
 * @param {string[]} files - List of file paths to stage
 * @param {string} message - Commit message
 */
export function commitFiles(files, message) {
    for (const file of files) {
        git(`add "${file}"`);
    }
    git(`commit -m "${message}"`);
}

/**
 * Get the most recent git tags sorted by version, descending.
 * @param {number} [count=10]
 * @returns {string[]}
 */
export function getTagHistory(count = 10) {
    const result = git('tag -l --sort=-v:refname');
    if (!result) return [];
    return result.split('\n').filter(Boolean).slice(0, count);
}
