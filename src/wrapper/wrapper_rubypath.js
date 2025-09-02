#!/usr/bin/env node

const Wrapper = require('../cli/_wrapper');

const cwd = process.argv[2];

let version = Wrapper.getRubyVersionForPath(cwd);

// add path to ensure "ruby -S" is working
let path_var = "";
if(Wrapper.getPathOfMatchingRubyVersion(version)) {
    let ruby_path = Wrapper.getPathOfMatchingRubyVersion(version);
    // ensure backslashes for windows, as in PATHs, slashes are not allowed
    ruby_path = ruby_path.replaceAll(/\//g, '\\');
    path_var = `set "RUBYPATH=${ruby_path}/bin"`;
} else {
    path_var = `@echo off`;
}

const final_command = `${path_var}`;
console.log(final_command);