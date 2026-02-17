import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { error } from './ui.js';

/**
 * Read and parse a JSON file from the current working directory.
 * @param {string} filename
 * @returns {object|null}
 */
function readJsonFile(filename) {
    const filePath = join(process.cwd(), filename);
    if (!existsSync(filePath)) return null;
    return JSON.parse(readFileSync(filePath, 'utf8'));
}

/**
 * Write an object as formatted JSON to a file in the current working directory.
 * @param {string} filename
 * @param {object} data
 */
function writeJsonFile(filename, data) {
    const filePath = join(process.cwd(), filename);
    writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

/**
 * Get the current version string from package.json.
 * @returns {string} e.g. "1.2.3" or "1.2.3.1"
 */
export function getCurrentVersion() {
    const pkg = readJsonFile('package.json');
    if (!pkg) {
        error('package.json not found in current directory.');
        process.exit(1);
    }
    return pkg.version;
}

/**
 * Parse a version string into its numeric components.
 * @param {string} version
 * @returns {{ major: number, minor: number, patch: number, hotfix: number|null }}
 */
export function parseVersion(version) {
    const parts = version.split('.').map(Number);
    return {
        major: parts[0] || 0,
        minor: parts[1] || 0,
        patch: parts[2] || 0,
        hotfix: parts.length > 3 ? parts[3] : null,
    };
}

/**
 * Calculate the next version string for a given bump type.
 * @param {'major'|'minor'|'patch'|'hotfix'} type
 * @param {string} currentVersion
 * @returns {string}
 */
export function bumpVersion(type, currentVersion) {
    const { major, minor, patch, hotfix } = parseVersion(currentVersion);

    switch (type) {
        case 'major':
            return `${major + 1}.0.0`;
        case 'minor':
            return `${major}.${minor + 1}.0`;
        case 'patch':
            return `${major}.${minor}.${patch + 1}`;
        case 'hotfix':
            return hotfix === null
                ? `${major}.${minor}.${patch}.1`
                : `${major}.${minor}.${patch}.${hotfix + 1}`;
        default:
            error(`Unknown bump type: ${type}`);
            process.exit(1);
    }
}

/**
 * Build the full tag name with an optional project prefix.
 * @param {string} version
 * @param {string} [prefix]
 * @returns {string} e.g. "v1.2.3" or "xp-v1.2.3"
 */
export function buildTagName(version, prefix) {
    return prefix ? `${prefix}-v${version}` : `v${version}`;
}

/**
 * Update the version field in package.json and package-lock.json (if present).
 * @param {string} newVersion
 */
export function updatePackageFiles(newVersion) {
    // Update package.json
    const pkg = readJsonFile('package.json');
    if (!pkg) {
        error('package.json not found.');
        process.exit(1);
    }
    pkg.version = newVersion;
    writeJsonFile('package.json', pkg);

    // Update package-lock.json if it exists
    const pkgLock = readJsonFile('package-lock.json');
    if (pkgLock) {
        pkgLock.version = newVersion;
        if (pkgLock.packages && pkgLock.packages['']) {
            pkgLock.packages[''].version = newVersion;
        }
        writeJsonFile('package-lock.json', pkgLock);
    }
}
