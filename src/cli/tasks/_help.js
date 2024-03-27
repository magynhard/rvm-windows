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
            {name: 'add <path>', alias: 'a', summary: 'Add a installed ruby environment to the list'},
            {name: 'current', alias: 'c', summary: 'Print current ruby version'},
            {name: 'help', alias: 'h', summary: 'Print this usage guide'},
            {name: 'install', alias: 'i', summary: 'Install a specific ruby version'},
            {name: 'list', alias: 'l', summary: 'List all installed ruby versions managed by RVM'},
            {name: 'update', alias: 'up', summary: 'Check for RVM updates'},
            {name: 'use', alias: 'u', summary: 'Switch to specified ruby version'},
            {name: 'version', alias: 'v', summary: 'Display build version'},
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
