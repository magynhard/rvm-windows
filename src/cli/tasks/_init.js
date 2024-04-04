#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const {execSync} = require('child_process');

var RvmCliTools = require('./../_tools');
var RvmCliFix = require('./../tasks/_fix');
var RvmCliScan = require('./../tasks/_scan');

class RvmCliInit {
    static initAfterInstall(force = false) {
        const self = RvmCliInit;
        if(!File.isExisting(RvmCliTools.rvmConfigPath()) || true) {
            RvmCliFix.fixConfig();
            RvmCliScan.scan();
            console.log(`RVM has been initialized and is ready to use!`);
        }
    }
}

module.exports = RvmCliInit;


