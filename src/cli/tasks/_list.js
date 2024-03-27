#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const {execSync} = require('child_process');
const Chalk = require('chalk');

var RvmCliTools = require('./../_tools');

class RvmCliList {
    static list() {
        const self = RvmCliList;
        const config = RvmCliTools.config();
        config.envs.eachWithIndex((version, path) => {
            let prefix = "  ";
            if (version === config.current) {
                if(version === config.default) {
                    prefix = "=*";
                } else {
                    prefix = "=>";
                }
            } else if (version === config.default) {
                prefix = " *";
            }
            console.log(`${prefix} ${Chalk.green(version)}`);
        });
        self.legend();
    }

    static versions() {
        const self = RvmCliList;
        return Object.keys(RvmCliTools.config().envs);
    }

    static legend() {
        const self = RvmCliList;
        console.log();
        console.log(`# => - current`);
        console.log(`# =* - current && default`);
        console.log(`#  * - default`);
    }
}

module.exports = RvmCliList;


