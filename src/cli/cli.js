#!/usr/bin/env node

const commandLineArgs = require('command-line-args');
const chalk = require('chalk');

const RvmCliTools = require('./_tools');
const RvmCliHelp = require('./tasks/_help');
const RvmCliSetup = require('./tasks/_setup');
const RvmCliList = require("./tasks/_list");


const taskDefinitions = [
    {name: 'command', type: String, multiple: true, defaultOption: true}, // fall back command
    {name: 'help', alias: 'h', type: Boolean},
    {name: 'version', alias: 'v', type: Boolean},
]

const tasks = commandLineArgs(taskDefinitions, {partial: true});

function logo() {
    console.log(RvmCliTools.logo());
}

RvmCliSetup.ensureWrapperPathEnvIsSet(true);

//
// version
//
if (tasks.version || tasks.command && (tasks.command[0] === 'version' || tasks.command[0] === 'v')) {
    const RvmCliVersion = require('./tasks/_version');
    RvmCliVersion.version();
}
//
// help
//
else if (Object.keys(tasks).length === 0 || tasks.help || tasks.command && (tasks.command[0] === 'help' || tasks.command[0] === 'h')) {
    logo();
    RvmCliHelp.help();
}
//
// current
//
else if (tasks.current || tasks.command && (tasks.command[0] === 'current' || tasks.command[0] === 'c')) {
    const RvmListCurrent = require('./tasks/_current');
    RvmListCurrent.current();
}
//
// install
//
else if (tasks.install || tasks.command && (tasks.command[0] === 'install' || tasks.command[0] === 'i')) {
    const RvmListInstall = require('./tasks/_install');
    RvmListInstall.install();
}
//
// list
//
else if (tasks.list || tasks.command && (tasks.command[0] === 'list' || tasks.command[0] === 'l')) {
    const RvmCliList = require('./tasks/_list');
    if(tasks.command[1] === 'known') {
        RvmCliList.listKnown();
    } else {
        RvmCliList.list();
    }
}
//
// use
//
else if (tasks.use || tasks.command && (tasks.command[0] === 'use' || tasks.command[0] === 'u')) {
    const RvmCliUse = require('./tasks/_use');
    RvmCliUse.use();
} else {
    logo();
    let unknown_option = tasks ? tasks.command ? tasks.command[0] : tasks._unknown[0].replace(/-/g,'') : tasks._unknown[0].replace(/-/g,'');
    RvmCliHelp.unknown(unknown_option);
}
