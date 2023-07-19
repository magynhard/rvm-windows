#!/usr/bin/env node

const commandLineArgs = require('command-line-args');
const chalk = require('chalk');

const GroboCliTools = require('./_tools');
const GroboCliHelp = require('./tasks/_help');

const taskDefinitions = [
    {name: 'command', type: String, multiple: true, defaultOption: true}, // fall back command
    {name: 'help', alias: 'h', type: Boolean},
    {name: 'version', alias: 'v', type: Boolean},
]

const tasks = commandLineArgs(taskDefinitions, {partial: true});

function logo() {
    console.log(GroboCliTools.logo());
}


//
// version
//
if (tasks.version || tasks.command && (tasks.command[0] === 'version' || tasks.command[0] === 'v')) {
    const GroboCliVersion = require('./tasks/_version');
    GroboCliVersion.version();
}
//
// help
//
else if (Object.keys(tasks).length === 0 || tasks.help || tasks.command && (tasks.command[0] === 'help' || tasks.command[0] === 'h')) {
    logo();
    GroboCliHelp.help();
} else {
    logo();
    let unknown_option = tasks ? tasks.command ? tasks.command[0] : tasks._unknown[0].replace(/-/g,'') : tasks._unknown[0].replace(/-/g,'');
    GroboCliHelp.unknown(unknown_option);
}
