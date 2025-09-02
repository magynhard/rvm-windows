#!/usr/bin/env node

const RvmCliTools = require('../cli/_tools');
const Wrapper = require('../cli/_wrapper');
const File = require('ruby-nice/file');

let wrapper_path = RvmCliTools.getRvmDataDir() + '\\wrapper';
// ensure backslashes for windows, as in PATHs, slashes are not allowed
wrapper_path = wrapper_path.replaceAll(/\//g, '\\');

// add path temporary to not pollute the original PATH env
let path_var = "";
if(RvmCliTools.getCurrentVersion() !== "system") {
    path_var = `set "PATH=${wrapper_path};%PATH%"`;
} else {
    path_var = `@echo off`;
}

const final_command = `${path_var}`;
console.log(final_command);