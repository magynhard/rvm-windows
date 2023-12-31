#!/usr/bin/env node

const chalk = require('chalk');
const commandLineUsage = require('command-line-usage');
const RvmCliTools = require('./../_tools');

class RvmCliHelp {
    static help() {
        const self = RvmCliHelp;
        let section = RvmCliTools.colorizeValues(self.SECTIONS.help, ['name', 'alias', 'example'], 'redBright');
        const usage = commandLineUsage(section);
        console.log(usage);
    }

    static unknown(task) {
        const self = RvmCliHelp;
        let section = self.SECTIONS.unknown;
        section[0].content = section[0].content.replace('{{task}}', chalk.red(task));
        section = RvmCliTools.colorizeValues(section, ['name', 'alias', 'example'], 'redBright');
        const usage = commandLineUsage(section);
        console.log(usage);
    }
}

RvmCliHelp.SECTIONS = {};
RvmCliHelp.SECTIONS.help = [
    {
        header: 'RVM CLI',
        content: `The RVM CLI (rvm) provides several interactive tasks to ensure programmers happyness. 😊`
    },
    {
        header: 'Available tasks',
        content: 'Use either the full length task or its shortcut.'
    },
    {
        content: [
            {name: 'help', alias: 'h', summary: 'Print this usage guide'},
            {name: 'install', alias: 'i', summary: 'Install a specified ruby version'},
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
                desc: 'Full length task, its shortcut is {redBright v}'
            },
            {
                example: 'rvm h',
                desc: 'Shortcut task for {redBright help}'
            },
        ]
    }
];

RvmCliHelp.SECTIONS.unknown = [
    {
        header: 'Invalid task',
        content: `The given task {{task}} is invalid. Run the command with task ${chalk.redBright('help')} to get information about valid tasks.`
    }
];

module.exports = RvmCliHelp;
