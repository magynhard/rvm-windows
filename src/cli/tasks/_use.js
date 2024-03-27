#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const {execSync} = require('child_process');
const Chalk = require('chalk');

var RvmCliTools = require('./../_tools');
var RvmCliList = require('./_list');

class RvmCliUse {
    static use() {
        const self = RvmCliUse;
        let arg = process.argv[3];
        if(!arg) {
            console.error(`No version given. Run ${Chalk.green('rvm use <version>')}, for example: ${Chalk.green('rvm use ruby-3.2.2')}`);
            process.exit(1);
        }
        // prefix ruby- if it starts with number
        if(self._startsWithNumber(arg)) {
            arg = "ruby-" + arg;
        }
        let match = self._matchingVersion(arg);
        if(arg === "default") {
            match = RvmCliTools.config().default;
        }
        if(match) {
            let config = RvmCliTools.config();
            config.current = match;
            RvmCliTools.writeRvmConfig(config);
            console.log(`Using ${Chalk.green(match)} ...`);
        } else {
            console.error(`No version for ${Chalk.red(arg)} available! Run ${Chalk.green('rvm list')} to show available versions.`);
        }
    }

    static _startsWithNumber(content) {
        return `${parseInt(content[0])}` === content[0];
    }

    static _matchingVersion(version) {
        const self = RvmCliUse;
        let match = null;
        // direct match
        if(RvmCliList.versions().includes(version)) {
            return version;
        } else {
            let split = version.split(".");
            // minor match
            if(split.length === 2) {
                const minor_version = split[0] + "." + split[1];
                let version_match = null;
                RvmCliList.versions().sort().reverse().eachWithIndex((v) => {
                    if(v.startsWith(`${minor_version}.`)) {
                        version_match = v;
                        return false; // break
                    }
                });
                if(version_match) {
                    return version_match;
                }
            } else if(split.length === 1) {
                let version_match = null;
                RvmCliList.versions().sort().reverse().eachWithIndex((v) => {
                   if(v.startsWith(`${split[0]}.`)) {
                       version_match = v;
                       return false;
                   }
                });
                if(version_match) {
                    return version_match;
                }
            }
        }
    }
}

module.exports = RvmCliUse;


