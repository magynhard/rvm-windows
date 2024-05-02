#!/usr/bin/env node

const Chalk = require('chalk');
const CommandLineUsage = require('command-line-usage');
const RvmCliTools = require('./../_tools');

class RvmCliHelp {
    static help() {
        const self = RvmCliHelp;
        let section = RvmCliTools.colorizeValues(self.SECTIONS.help, ['name', 'alias', 'example'], 'green');
        const usage = CommandLineUsage(section);
        console.log(usage);
    }

    static unknown(task) {
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
        content: 'Use either the full length task or its shortcut.'
    },
    {
        content: [
            {name: 'add <path>', alias: 'a', summary: 'Add a installed ruby environment to the list (alias: mount)'},
            {name: 'automount', alias: 'am', summary: 'Scan for ruby installations and add them to the RVM configuration (alias: scan)'},
            {name: 'config', alias: 'cfg', summary: 'Print current RVM config'},
            {name: 'current', alias: 'c', summary: 'Print current ruby version'},
            {name: 'delete', alias: 'd', summary: 'Delete current or given ruby and delete its sources (alias: remove)'},
            {name: 'fix', alias: 'f', summary: 'Automatically fix paths and versions in RVM configuration'},
            {name: 'get stable', alias: '', summary: 'Upgrade RVM to its latest stable version'},
            {name: 'help', alias: 'h', summary: 'Print this usage guide'},
            {name: 'init', alias: '', summary: 'Initialize RVM by adding to PATH environment variable'},
            {name: 'install <version>', alias: 'i', summary: 'Install a specific ruby version'},
            {name: 'kit', alias: 'k', summary: 'Install x64 dependencies to build native gems like postgresql, mysql2, ...'},
            {name: 'list', alias: 'l', summary: 'List all installed ruby versions managed by RVM'},
            {name: 'list verbose', alias: '', summary: 'List all installed ruby versions managed by RVM with additional info'},
            {name: 'list known', alias: '', summary: 'List all installable ruby versions'},
            {name: 'mount <path>', alias: 'm', summary: 'Add a installed ruby environment to the list (alias: add)'},
            {name: 'remove', alias: 'r', summary: 'Remove current or given ruby and delete its sources (alias: delete)'},
            {name: 'scan', alias: 's', summary: 'Scan for ruby installations and add them to the RVM configuration (alias: automount)'},
            {name: 'uninstall <version>', alias: 'ui', summary: 'Uninstall current or given version, keeping itqs sources'},
            {name: 'upgrade <from_version> <to_version>', alias: 'up', summary: 'Update current or given version to given version qor latest patch version'},
            {name: 'use <version>', alias: 'u', summary: 'Switch to specified ruby version'},
            {name: 'version', alias: 'v', summary: 'Display RVM build version'},
        ]
    },
    {
        header: 'Examples',
        content: [
            {
                example: 'rvm version',
                desc: 'Full length task, its shortcut is {green v}'
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
