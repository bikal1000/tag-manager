#!/usr/bin/env node

import { existsSync } from 'node:fs';
import { Command } from 'commander';
import chalk from 'chalk';

import { getCurrentVersion, bumpVersion, buildTagName, updatePackageFiles } from '../lib/version.js';
import { ensureGitRepo, ensureCleanWorkingTree, tagExists, createTag, commitFiles, getTagHistory } from '../lib/git.js';
import { info, success, error, dim, printVersion, promptMenu, confirm, pressEnter, divider, banner } from '../lib/ui.js';

// ─── Core actions ────────────────────────────────────────────────────

/**
 * Execute a version bump: update files, commit, and create a git tag.
 * @param {'major'|'minor'|'patch'|'hotfix'} type
 * @param {object} options
 * @param {string}  [options.prefix]       Optional project prefix
 * @param {boolean} [options.skipConfirm]  Skip the confirmation prompt
 */
async function doBump(type, { prefix, skipConfirm = false } = {}) {
    ensureGitRepo();
    ensureCleanWorkingTree();

    const currentVersion = getCurrentVersion();
    const newVersion = bumpVersion(type, currentVersion);
    const tagName = buildTagName(newVersion, prefix);

    // Ensure the tag doesn't already exist
    if (tagExists(tagName)) {
        error(`Tag ${chalk.bold(tagName)} already exists.`);
        process.exit(1);
    }

    console.log('');
    printVersion('Current version:', currentVersion);
    printVersion('New version:    ', newVersion);
    if (prefix) info(`Tag prefix:      ${chalk.bold(prefix)}`);
    console.log(`${chalk.blue('Tag name:        ')}${chalk.green.bold(tagName)}`);
    console.log('');

    // Confirm unless skipped (CLI mode skips by default)
    if (!skipConfirm) {
        const ok = await confirm('Proceed with version bump?');
        if (!ok) {
            error('Operation cancelled.');
            return;
        }
    }

    // 1. Update package files
    updatePackageFiles(newVersion);
    success(`✔ Updated package.json → ${newVersion}`);

    // 2. Commit changes
    const filesToCommit = ['package.json'];
    if (existsSync('package-lock.json')) filesToCommit.push('package-lock.json');
    commitFiles(filesToCommit, tagName);
    success(`✔ Committed: ${tagName}`);

    // 3. Create annotated git tag
    createTag(tagName, tagName);
    success(`✔ Created tag: ${tagName}`);

    console.log('');
    divider();
    success(`✨ Version ${chalk.bold(tagName)} created locally!`);
    divider();
    console.log('');
    info('To publish this version:');
    dim(`  1. Review your changes`);
    dim(`  2. git push origin <branch>`);
    dim(`  3. git push origin ${tagName}`);
    console.log('');
}

/**
 * Display version history (recent git tags).
 */
function doHistory() {
    ensureGitRepo();
    const tags = getTagHistory(15);

    console.log('');
    if (tags.length === 0) {
        dim('No tags found in this repository.');
    } else {
        info(`Version history (last ${tags.length} tags):`);
        console.log('');
        tags.forEach((tag, i) => {
            const marker = i === 0 ? chalk.green('→') : chalk.dim('·');
            const text = i === 0 ? chalk.green.bold(tag) : chalk.white(tag);
            console.log(`  ${marker} ${text}`);
        });
    }
    console.log('');
}

// ─── Interactive mode ────────────────────────────────────────────────

async function interactiveMode() {
    ensureGitRepo();

    while (true) {
        console.clear();
        banner('Tag Manager');
        printVersion('Current version:', getCurrentVersion());
        console.log('');

        const action = await promptMenu();

        if (action === 'exit') {
            console.log('');
            info('Goodbye! 👋');
            console.log('');
            break;
        }

        if (action === 'history') {
            doHistory();
            await pressEnter();
            continue;
        }

        // major, minor, patch, or hotfix
        await doBump(action, { skipConfirm: false });
        await pressEnter();
    }
}

// ─── CLI definition ──────────────────────────────────────────────────

const program = new Command();

program
    .name('tag')
    .description('A cross-platform CLI for managing semantic versioning tags in Git repositories.')
    .version('2.0.0', '-v, --version', 'Display the CLI version');

program
    .command('major [prefix]')
    .description('Bump major version (X.0.0) — breaking changes')
    .action((prefix) => doBump('major', { prefix, skipConfirm: true }));

program
    .command('minor [prefix]')
    .description('Bump minor version (x.X.0) — new features')
    .action((prefix) => doBump('minor', { prefix, skipConfirm: true }));

program
    .command('patch [prefix]')
    .description('Bump patch version (x.x.X) — bug fixes')
    .action((prefix) => doBump('patch', { prefix, skipConfirm: true }));

program
    .command('hotfix [prefix]')
    .description('Bump hotfix version (x.x.x.X) — quick fixes')
    .action((prefix) => doBump('hotfix', { prefix, skipConfirm: true }));

program
    .command('history')
    .description('View recent version history')
    .action(() => doHistory());

// If no subcommand is provided, run interactive mode
program.action(() => interactiveMode());

program.parse();
