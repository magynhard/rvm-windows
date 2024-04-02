#!/usr/bin/env node

const Wrapper = require('../cli/_wrapper');

const cwd = process.argv[2];
const command = process.argv[3].split(".")[0];

const version = Wrapper.getRubyVersionForPath(cwd);

if(Wrapper.hasRubyEnvCommand(version, command)) {
    console.log(`"${Wrapper.getRubyEnvCommandPath(version, command)}"`);
} else {
    console.log(`echo "'${command}' is not recognized as an internal or external command,\noperable program or batch file." && exit /b 9009`);
}