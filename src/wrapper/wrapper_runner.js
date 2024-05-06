#!/usr/bin/env node

const RvmCliUse = require('../cli/tasks/_use');
const RvmCliList = require('../cli/tasks/_list');
const RvmCliTools = require('../cli/_tools');
const Wrapper = require('../cli/_wrapper');

const cwd = process.argv[2];
const command = process.argv[3].split(".")[0];

let version = Wrapper.getRubyVersionForPath(cwd);

var final_command = "";

if(Wrapper.hasRubyEnvCommand(version, command)) {
    final_command = `"${Wrapper.getRubyEnvCommandPath(version, command)}"`;
} else if(Wrapper.hasRubyEnvCommand(RvmCliTools.getCurrentVersion(), command)) {
    const current_version = RvmCliTools.getCurrentVersion();
    final_command = `"${Wrapper.getRubyEnvCommandPath(current_version, command)}"`;
} else {
    console.log(`@echo off && echo '${command}' is not recognized as an internal or external command, operable program or batch file. && exit /b 9009`);
    process.exit(9009);
}

console.log(final_command);