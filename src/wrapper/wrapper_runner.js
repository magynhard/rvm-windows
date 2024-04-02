#!/usr/bin/env node

const RvmCliUse = require('../cli/tasks/_use');
const RvmCliList = require('../cli/tasks/_list');
const RvmCliTools = require('../cli/_tools');
const Wrapper = require('../cli/_wrapper');

const cwd = process.argv[2];
const command = process.argv[3].split(".")[0];

const version = Wrapper.getRubyVersionForPath(cwd);

if(Wrapper.hasRubyEnvCommand(version, command)) {
    console.log(`"${Wrapper.getRubyEnvCommandPath(version, command)}"`);
} else if(Wrapper.hasRubyEnvCommand(RvmCliTools.config().current, command)) {
    const current_version = RvmCliTools.config().current;
    console.log(`"${Wrapper.getRubyEnvCommandPath(current_version, command)}"`);
} else {
    console.log(`@echo off && echo '${command}' is not recognized as an internal or external command, operable program or batch file. && exit /b 9009`);
}