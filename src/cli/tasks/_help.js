#!/usr/bin/env node

const Chalk = require('chalk');
const CommandLineUsage = require('command-line-usage');
const RvmCliTools = require('./../_tools');

class RvmCliHelp {
    static runHelp() {
        const self = RvmCliHelp;
        let section = RvmCliTools.colorizeValues(self.SECTIONS.help, ['name', 'alias', 'example'], 'green');
        const usage = CommandLineUsage(section);
        console.log(usage);
    }

    static runUnknownCommand(task) {
        const self = RvmCliHelp;
        let section = self.SECTIONS.unknown;
        section[0].content = section[0].content.replace('{{task}}', Chalk.red(task));
        section = RvmCliTools.colorizeValues(section, ['name', 'alias', 'example'], 'green');
        const usage = CommandLineUsage(section);
        console.log(usage);
    }
}

RvmCliHelp.SECTIONS = {};
RvmCliHelp.SECTIONS.help = [
    {
        header: 'RVM CLI',
        content: `The RVM CLI (rvm) provides several interactive tasks to ensure programmers happyness when working with several ruby environments on windows. 😊`
    },
    {
        header: 'Available tasks',
        content: 'Use either the full length task name or its shortcut.'
    },
    {
        content: [
            {name: 'add <path>', alias: 'a', summary: 'Add a installed ruby environment to the list (alias: mount)'},
            {name: 'automount', alias: 'am', summary: 'Scan for ruby installations and add them to the RVM configuration (alias: scan)'},
            {name: 'config', alias: 'cfg', summary: 'Print current RVM config'},
            {name: 'config default', alias: 'cfg d', summary: 'Print default version'},
            {name: 'config default <version>', alias: 'cfg d <version>', summary: 'Set default version'},
            {name: 'config proxy', alias: 'cfg p', summary: 'Get the configured proxy host.'},
            {name: 'config proxy <host>', alias: 'cfg p <host>', summary: 'Set the proxy server host. E.g. http://proxy:12345'},
            {name: 'config proxy delete', alias: 'cfg p delete', summary: 'Remove the proxy server host from the configuration.'},
            {name: 'config proxy enable', alias: 'cfg p enable', summary: 'Enable using the proxy server host from the configuration.'},
            {name: 'config proxy disable', alias: 'cfg p disable', summary: 'Disable using the proxy server host from the configuration.'},
            {name: 'current', alias: 'c', summary: 'Print current ruby environment version'},
            {name: 'default', alias: 'd', summary: 'Use default ruby version (alias: rvm use default)'},
            {name: 'delete <version>', alias: 'del <version>', summary: 'Delete given ruby environment (alias: remove)'},
            {name: 'fix', alias: 'f', summary: 'Automatically fix paths and versions in RVM configuration'},
            {name: 'get', alias: 'g', summary: 'Upgrade RVM to its latest release version'},
            {name: 'help', alias: 'h', summary: 'Print this usage guide'},
            {name: 'info', alias: '', summary: 'Show the environment information for current ruby'},
            {name: 'init', alias: '', summary: 'Initialize RVM by adding it to the PATH environment variable'},
            {name: 'install <version>', alias: 'i <version>', summary: 'Install a specific ruby version'},
            {name: 'kick <version>', alias: '', summary: 'Only remove given ruby environment from the RVM list without deleting any ruby environment.'},
            {name: 'kit', alias: 'k', summary: 'Install a bunch of widely used x64 dependencies automatically to the current ruby environment, which are needed to build native gems like postgresql, mysql2, ...'},
            {name: 'list', alias: 'l ls', summary: 'List all installed ruby versions managed by RVM'},
            {name: 'list all', alias: 'la', summary: 'List all installable ruby versions'},
            {name: 'list known', alias: 'lk', summary: 'List all installable ruby versions with latest patch version'},
            {name: 'list upgrades', alias: 'lu', summary: 'List all installed ruby versions and their available upgrade versions'},
            {name: 'list verbose', alias: 'lv', summary: 'List all installed ruby versions managed by RVM with additional info'},
            {name: 'mount <path>', alias: 'm', summary: 'Add a installed ruby environment to the list (alias: add <path>)'},
            {name: 'reinstall <version>', alias: 'r <version>', summary: 'Delete given ruby environment and install it again.'},
            {name: 'remove <version>', alias: 'rem <version>', summary: 'Delete given ruby environment (alias: uninstall)'},
            {name: 'scan', alias: '', summary: 'Scan for ruby installations and add them to the RVM configuration (alias: automount)'},
            {name: 'system', alias: 's', summary: 'Use the system ruby (alias: rvm use system)'},
            {name: 'uninstall <version>', alias: 'ui <version>', summary: 'Delete given ruby environment (alias: remove)'},
            {name: 'upgrade <version>', alias: 'up <version>', summary: 'Upgrade given version to its latest patch version'},
            {name: 'upgrade <from> <to>', alias: 'up <from> <to>', summary: 'Upgrade given from_version to given to_version'},
            {name: 'use <version>', alias: 'u <version>', summary: 'Switch to specified ruby version'},
            {name: 'version', alias: 'v', summary: 'Display RVM build version'},
        ]
    },
    {
        header: 'Examples',
        content: [
            {
                example: 'rvm version',
                desc: 'Full name task, its shortcut is {green v}'
            },
            {
                example: 'rvm h',
                desc: 'Shortcut task for {green help}'
            },
        ]
    }
];

RvmCliHelp.SECTIONS.unknown = [
    {
        header: 'Invalid task',
        content: `The given task {{task}} is invalid. Run the command with task ${Chalk.green('help')} to get information about valid tasks.`
    }
];

module.exports = RvmCliHelp;
