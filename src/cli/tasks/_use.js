#!/usr/bin/env node

const {execSync} = require('child_process');
const Chalk = require('chalk');

var RvmCliTools = require('./../_tools');
var RvmCliFix = require('./_fix');
var RvmCliDefault = require('./_default');

class RvmCliUse {
    static runUse(version) {
        const self = RvmCliUse;
        version = version || process.argv[3];
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
        else if(version === "default") {
            version = RvmCliTools.config().default || RvmCliTools.config().envs[0];
        }
        // prefix ruby- if it starts with number
        if(RvmCliTools.startsWithNumber(version)) {
            version = "ruby-" + version;
        }
        let match = RvmCliTools.matchingVersion(version);
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


    /**
     * Check of currently set "default" and "current" versions are available or set at all.
     * Then reset if needed.
     */
    static fixDefaultAndCurrent() {
        const self = RvmCliTools;
        execSync(`rvm fix`);
        const new_version = Object.keys(RvmCliTools.config().envs)[0];
        const default_version = RvmCliTools.config().default;
        const current_version = self.getCurrentVersion();
        if (!RvmCliTools.config().envs[current_version]) {
            if (RvmCliTools.config().envs[default_version]) {
                RvmCliUse.runUse(default_version);
            } else if(new_version) {
                RvmCliUse.runUse(new_version);
            }
        }
        if(!RvmCliTools.config().envs[default_version]) {
            if (RvmCliTools.config().envs[current_version]) {
                RvmCliDefault.runDefault(current_version);
            } else if(new_version) {
                RvmCliDefault.runDefault(new_version);
            }
        }
    }
}

module.exports = RvmCliUse;


