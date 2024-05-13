#!/usr/bin/env node

const commandLineArgs = require('command-line-args');
const chalk = require('chalk');

const RvmCliTools = require('./_tools');
const RvmCliHelp = require('./tasks/_help');
const RvmCliList = require("./tasks/_list");
const RvmCliFix = require('./tasks/_fix');
const RvmCliScan = require('./tasks/_scan');
const RvmCliInit = require('./tasks/_init');

const Wrapper = require("./_wrapper");

const taskDefinitions = [
    {name: 'command', type: String, multiple: true, defaultOption: true}, // fall back command
    {name: 'help', alias: 'h', type: Boolean},
    {name: 'version', alias: 'v', type: Boolean},
]

const tasks = commandLineArgs(taskDefinitions, {partial: true});

RvmCliInit.initAfterInstall();
RvmCliInit.initSessionToRvmExes();

function logo() {
    console.log(RvmCliTools.logo());
}

//
// version
//
if (tasks.version || tasks.command && (tasks.command[0] === 'version' || tasks.command[0] === 'v')) {
    const RvmCliVersion = require('./tasks/_version');
    RvmCliVersion.runVersion();
}
//
// add
//
else if (tasks.add || tasks.mount || tasks.command && (tasks.command[0] === 'add' || tasks.command[0] === 'a' || tasks.command[0] === 'mount' || tasks.command[0] === 'm')) {
    const RvmCliAdd = require('./tasks/_add');
    RvmCliAdd.runAdd();
}
//
// help
//
else if (Object.keys(tasks).length === 0 || tasks.help || tasks.command && (tasks.command[0] === 'help' || tasks.command[0] === 'h')) {
    logo();
    RvmCliHelp.runHelp();
}
//
// init
//
else if (tasks.init || tasks.command && (tasks.command[0] === 'init')) {
    RvmCliInit.initAfterInstall(true);
}
//
// config
//
else if (tasks.config || tasks.command && (tasks.command[0] === 'config' || tasks.command[0] === 'cfg')) {
    const RvmCliConfig = require('./tasks/_config');
    RvmCliConfig.runConfig();
}
//
// current
//
else if (tasks.current || tasks.command && (tasks.command[0] === 'current' || tasks.command[0] === 'c')) {
    const RvmCliCurrent = require('./tasks/_current');
    RvmCliCurrent.runCurrent();
}
//
// default
//
else if (tasks.default || tasks.command && (tasks.command[0] === 'default' || tasks.command[0] === 'd')) {
    const RvmCliDefault = require('./tasks/_default');
    RvmCliDefault.runDefault();
}
//
// fix
//
else if (tasks.fix || tasks.command && (tasks.command[0] === 'fix' || tasks.command[0] === 'f')) {
    RvmCliFix.runFix();
}
//
// install
//
else if (tasks.install || tasks.command && (tasks.command[0] === 'install' || tasks.command[0] === 'i')) {
    const RvmListInstall = require('./tasks/_install');
    RvmListInstall.runInstall();
}
//
// scan
//
else if (tasks.scan || tasks.automount || tasks.command && (tasks.command[0] === 'scan' || tasks.command[0] === 's' || tasks.command[0] === 'automount' || tasks.command[0] === 'am')) {
    RvmCliScan.runScan();
}
//
// kit
//
else if (tasks.kit || tasks.command && (tasks.command[0] === 'kit' || tasks.command[0] === 'k')) {
    const RvmCliKit = require('./tasks/_kit');
    RvmCliKit.runKit();
}
//
// list
//
else if (tasks.list || tasks.command && (tasks.command[0] === 'list' || ['l','lv','la','lk','ls'].includes(tasks.command[0]))) {
    const RvmCliList = require('./tasks/_list');
    const f = tasks.command[0];
    const c = tasks.command[1];
    if(c === 'known' || f === 'lk') {
        RvmCliList.runListKnown();
    } else if(c === 'all' || f === 'la') {
        RvmCliList.runListAll();
    } else if(c === 'verbose' || c === 'v' || f === 'lv') {
        RvmCliList.runListVerbose();
    } else {
        RvmCliList.runList();
    }
}
//
// debug - only for developer purpose - put code to debug into this if block
//
else if (tasks.debug || tasks.command && (tasks.command[0] === 'debug')) {
    RvmCliList.runListVerbose();
}
//
// use
//
else if (tasks.use || tasks.command && (tasks.command[0] === 'use' || tasks.command[0] === 'u')) {
    const RvmCliUse = require('./tasks/_use');
    RvmCliUse.runUse();
} else {
    let unknown_option = tasks ? tasks.command ? tasks.command[0] : tasks._unknown[0].replace(/-/g,'') : tasks._unknown[0].replace(/-/g,'');
    RvmCliHelp.runUnknownCommand(unknown_option);
}
