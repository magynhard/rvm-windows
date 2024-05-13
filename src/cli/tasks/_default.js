#!/usr/bin/env node

const Chalk = require('chalk');

var RvmCliTools = require('./../_tools');

class RvmCliDefault {
    static runDefault() {
        const self = RvmCliDefault;
        let version = process.argv[3];
        if(version) {
            RvmCliTools.setDefaultVersion(version);
        } else {
            self.printDefault();
        }
    }

    static printDefault() {
        const self = RvmCliDefault;
        let config = RvmCliTools.config();
        if(config.default) {
            console.log(config.default);
        } else {
            console.log(`There is no default ruby version set. To set, run ${Chalk.green('rvm default <version>')}`);
        }
    }
}

module.exports = RvmCliDefault;


