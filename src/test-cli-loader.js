#!/usr/bin/env node

/**
 * Test CLI Loader - Loads all RVM tools for interactive testing
 * Usage: npm run test-cli
 */

const repl = require('repl');
const chalk = require('chalk');

// Load all RVM CLI tools
const RvmCliTools = require('./cli/_tools');
const RvmCliHelp = require('./cli/tasks/_help');
const RvmCliList = require('./cli/tasks/_list');
const RvmCliFix = require('./cli/tasks/_fix');
const RvmCliScan = require('./cli/tasks/_scan');
const RvmCliInit = require('./cli/tasks/_init');
const RvmCliAdd = require('./cli/tasks/_add');
const RvmCliConfig = require('./cli/tasks/_config');
const RvmCliCurrent = require('./cli/tasks/_current');
const RvmCliDefault = require('./cli/tasks/_default');
const RvmCliGet = require('./cli/tasks/_get');
const RvmCliInfo = require('./cli/tasks/_info');
const RvmCliInstall = require('./cli/tasks/_install');
const RvmCliKick = require('./cli/tasks/_kick');
const RvmCliKit = require('./cli/tasks/_kit');
const RvmCliReinstall = require('./cli/tasks/_reinstall');
const RvmCliSystem = require('./cli/tasks/_system');
const RvmCliUninstall = require('./cli/tasks/_uninstall');
const RvmCliUpgrade = require('./cli/tasks/_upgrade');
const RvmCliUse = require('./cli/tasks/_use');
const RvmCliVersion = require('./cli/tasks/_version');

const Wrapper = require('./cli/_wrapper');

require('ruby-nice/string');
require('ruby-nice/array');
require('ruby-nice/file');
require('ruby-nice/file-utils');

// Initialize RVM
console.log(chalk.cyan('🔧 Initializing RVM for testing...'));
RvmCliInit.initAfterInstall();
RvmCliInit.initSessionToRvmExes();
RvmCliInit.ensureWrapperIsFirstInPath();

console.log(RvmCliTools.logo());
console.log(chalk.green('\n✅ RVM Windows Test CLI loaded successfully!'));
console.log(chalk.yellow('📋 Available tools in global scope:'));
console.log(chalk.dim('   - RvmCliTools    - Core tools and utilities'));
console.log(chalk.dim('   - RvmCliHelp     - Help system'));
console.log(chalk.dim('   - RvmCliList     - List Ruby versions'));
console.log(chalk.dim('   - RvmCliFix      - Fix RVM installation'));
console.log(chalk.dim('   - RvmCliScan     - Scan for Ruby versions'));
console.log(chalk.dim('   - RvmCliInit     - Initialize RVM'));
console.log(chalk.dim('   - RvmCliAdd      - Add Ruby version'));
console.log(chalk.dim('   - RvmCliConfig   - Configuration management'));
console.log(chalk.dim('   - RvmCliCurrent  - Show current Ruby'));
console.log(chalk.dim('   - RvmCliDefault  - Set default Ruby'));
console.log(chalk.dim('   - RvmCliGet      - Get Ruby versions'));
console.log(chalk.dim('   - RvmCliInfo     - Show RVM info'));
console.log(chalk.dim('   - RvmCliInstall  - Install Ruby'));
console.log(chalk.dim('   - RvmCliKick     - Kick command'));
console.log(chalk.dim('   - RvmCliKit      - Kit management'));
console.log(chalk.dim('   - RvmCliReinstall- Reinstall Ruby'));
console.log(chalk.dim('   - RvmCliSystem   - System Ruby management'));
console.log(chalk.dim('   - RvmCliUninstall- Uninstall Ruby'));
console.log(chalk.dim('   - RvmCliUpgrade  - Upgrade Ruby'));
console.log(chalk.dim('   - RvmCliUse      - Use Ruby version'));
console.log(chalk.dim('   - RvmCliVersion  - Show version'));
console.log(chalk.dim('   - Wrapper        - Wrapper utilities'));
console.log(chalk.yellow('\n💡 Examples:'));
console.log(chalk.dim('   > RvmCliList.run()'));
console.log(chalk.dim('   > RvmCliCurrent.run()'));
console.log(chalk.dim('   > RvmCliInfo.run()'));
console.log(chalk.dim('   > RvmCliTools.getRubyVersions()'));
console.log(chalk.green('\n🚀 Starting interactive REPL...\n'));

// Start REPL with all tools available in context
const replServer = repl.start({
    prompt: chalk.magenta('rvm-test> '),
    useColors: true
});

// Add all tools to REPL context
replServer.context.RvmCliTools = RvmCliTools;
replServer.context.RvmCliHelp = RvmCliHelp;
replServer.context.RvmCliList = RvmCliList;
replServer.context.RvmCliFix = RvmCliFix;
replServer.context.RvmCliScan = RvmCliScan;
replServer.context.RvmCliInit = RvmCliInit;
replServer.context.RvmCliAdd = RvmCliAdd;
replServer.context.RvmCliConfig = RvmCliConfig;
replServer.context.RvmCliCurrent = RvmCliCurrent;
replServer.context.RvmCliDefault = RvmCliDefault;
replServer.context.RvmCliGet = RvmCliGet;
replServer.context.RvmCliInfo = RvmCliInfo;
replServer.context.RvmCliInstall = RvmCliInstall;
replServer.context.RvmCliKick = RvmCliKick;
replServer.context.RvmCliKit = RvmCliKit;
replServer.context.RvmCliReinstall = RvmCliReinstall;
replServer.context.RvmCliSystem = RvmCliSystem;
replServer.context.RvmCliUninstall = RvmCliUninstall;
replServer.context.RvmCliUpgrade = RvmCliUpgrade;
replServer.context.RvmCliUse = RvmCliUse;
replServer.context.RvmCliVersion = RvmCliVersion;
replServer.context.Wrapper = Wrapper;
replServer.context.String = String;

// Add shortcuts
replServer.context.list = () => RvmCliList.run();
replServer.context.current = () => RvmCliCurrent.run();
replServer.context.info = () => RvmCliInfo.run();
replServer.context.help = () => RvmCliHelp.run();
replServer.context.version = () => RvmCliVersion.run();

// Add chalk for colored output
replServer.context.chalk = chalk;

replServer.on('exit', () => {
    console.log(chalk.green('\n👋 Exiting RVM Test CLI. Goodbye!'));
    process.exit(0);
});
