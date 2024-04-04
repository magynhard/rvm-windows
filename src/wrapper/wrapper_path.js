#!/usr/bin/env node

const RvmCliTools = require('../cli/_tools');
const Wrapper = require('../cli/_wrapper');
const File = require('ruby-nice/file');

const wrapper_path = File.getHomePath() + '/.rvm/wrapper';

// add path temporary to not pollute the original PATH env
let path_var = "";
if(RvmCliTools.config().current !== "system") {
    path_var = `set "PATH=${wrapper_path}/bin;%PATH%"`;
} else {
    path_var = `@echo off`;
}

const final_command = `${path_var}`;
console.log(final_command);