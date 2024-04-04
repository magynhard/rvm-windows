#!/usr/bin/env node

const RvmCliUse = require('../cli/tasks/_use');
const RvmCliList = require('../cli/tasks/_list');
const RvmCliTools = require('../cli/_tools');
const Wrapper = require('../cli/_wrapper');

const cwd = process.argv[2];
const command = process.argv[3].split(".")[0];

let version = Wrapper.getRubyVersionForPath(cwd);

// add path to ensure "ruby -S" is working
let path_var = "";
if(Wrapper.getPathOfMatchingRubyVersion(version)) {
    path_var = `set "RUBYPATH=${Wrapper.getPathOfMatchingRubyVersion(version)}/bin"`;
} else {
    path_var = `@echo off`;
}

const final_command = `${path_var}`;
console.log(final_command);