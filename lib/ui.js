import chalk from 'chalk';
import inquirer from 'inquirer';

// ─── Styled output helpers ───────────────────────────────────────────

export const info = (msg) => console.log(chalk.blue(msg));
export const success = (msg) => console.log(chalk.green(msg));
export const error = (msg) => console.log(chalk.red(`Error: ${msg}`));
export const dim = (msg) => console.log(chalk.dim(msg));

/**
 * Print a key-value pair with colored label.
 */
export function printVersion(label, version) {
    console.log(`${chalk.blue(label)} ${chalk.green.bold(version)}`);
}

// ─── Interactive mode ────────────────────────────────────────────────

const MENU_CHOICES = [
    { name: `${chalk.yellow('Major')}  ${chalk.dim('(X.0.0)')}     — Breaking changes`, value: 'major' },
    { name: `${chalk.yellow('Minor')}  ${chalk.dim('(x.X.0)')}     — New features`, value: 'minor' },
    { name: `${chalk.yellow('Patch')}  ${chalk.dim('(x.x.X)')}     — Bug fixes`, value: 'patch' },
    { name: `${chalk.yellow('Hotfix')} ${chalk.dim('(x.x.x.X)')}   — Quick fixes`, value: 'hotfix' },
    new inquirer.Separator(),
    { name: `${chalk.cyan('View version history')}`, value: 'history' },
    { name: `${chalk.dim('Exit')}`, value: 'exit' },
];

/**
 * Show the interactive menu and return the user's selection.
 * @returns {Promise<string>}
 */
export async function promptMenu() {
    const { action } = await inquirer.prompt([
        {
            type: 'list',
            name: 'action',
            message: 'Select an action:',
            choices: MENU_CHOICES,
            loop: false,
        },
    ]);
    return action;
}

/**
 * Ask the user for a yes/no confirmation.
 * @param {string} message
 * @returns {Promise<boolean>}
 */
export async function confirm(message) {
    const { ok } = await inquirer.prompt([
        {
            type: 'confirm',
            name: 'ok',
            message,
            default: false,
        },
    ]);
    return ok;
}

/**
 * Ask the user to press Enter to continue.
 */
export async function pressEnter() {
    await inquirer.prompt([
        {
            type: 'input',
            name: '_',
            message: chalk.dim('Press Enter to continue...'),
        },
    ]);
}

/**
 * Print a horizontal divider.
 */
export function divider() {
    console.log(chalk.dim('─'.repeat(48)));
}

/**
 * Print a styled header banner.
 * @param {string} title
 */
export function banner(title) {
    console.log('');
    divider();
    console.log(chalk.bold.cyan(`  🏷️  ${title}`));
    divider();
    console.log('');
}
