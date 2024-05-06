#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const {execSync} = require('child_process');
const Chalk = require('chalk');

var RvmCliTools = require('./../_tools');
var RvmCliFix = require('./_fix');

class RvmCliUse {
    static use() {
        const self = RvmCliUse;
        let version = process.argv[3];
        let param = process.argv[4];
        if(version.startsWith("--")) {
            version = param;
        }
        if(RvmCliTools.startsWithNumber(param) && process.argv[3].startsWith("--")) {
            param = process.argv[3];
        }

        if(!version) {
            console.error(`No version given. Run ${Chalk.green('rvm use <version>')}, for example: ${Chalk.green('rvm use ruby-3.2.2')}`);
            process.exit(1);
        }
        // prefix ruby- if it starts with number
        if(RvmCliTools.startsWithNumber(version)) {
            version = "ruby-" + version;
        }
        let match = RvmCliTools.matchingVersion(version);
        if(version === "default") {
            match = RvmCliTools.config().default;
        }
        if(match) {
            RvmCliTools.setCurrentVersion(match);
            console.log(`Using ${Chalk.green(match)} from ${Chalk.green(RvmCliTools.config().envs[match])} ...`);
            RvmCliFix.fixWrapperFiles();
            if(param && param === "--default") {
                RvmCliTools.setDefaultVersion(version);
            }
        } else {
            console.error(`No version for ${Chalk.red(version)} available! Run ${Chalk.green('rvm list')} to show available versions.`);
        }
    }
}

module.exports = RvmCliUse;


