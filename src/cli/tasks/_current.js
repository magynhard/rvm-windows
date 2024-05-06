#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const {execSync} = require('child_process');
const Chalk = require('chalk');

var RvmCliTools = require('./../_tools');

class RvmCliCurrent {
    static current() {
        const self = RvmCliCurrent;
        console.log(RvmCliTools.getCurrentVersion());
    }
}

module.exports = RvmCliCurrent;


