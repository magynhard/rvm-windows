#!/usr/bin/env node
const {execSync} = require('child_process');
const Fs = require('fs');
const File = require('ruby-nice/file');

var RvmCliTools = require('./../_tools');
const Chalk = require("chalk");
const RvmCliUse = require("./_use");
const RvmCliFix = require("./_fix");

class RvmCliConfig {
    static runConfig() {
        const self = RvmCliConfig;
        const command = process.argv[3];
        if(["d", "default"].includes(command)) {
            self.runDefault();
        } else if(["p", "pd", "proxy"].includes(command)) {
            self.runProxy();
        } else {
            self.printConfig();
        }
    }

    static printConfig() {
        const config_path = RvmCliTools.rvmConfigPath();
        console.log(`RVM configuration at ${Chalk.green(config_path)}`);
        console.log()
        console.log(JSON.stringify(RvmCliTools.config(),null, 2));
    }

    static runDefault(version) {
        const self = RvmCliConfig;
        version = version || process.argv[4];
        if(version) {
            RvmCliTools.setDefaultVersion(version);
        } else {
            self.printDefault();
        }
    }

    static printDefault() {
        const self = RvmCliConfig;
        let config = RvmCliTools.config();
        if(config.default) {
            console.log(config.default);
        } else {
            console.log(`There is no default ruby version set. To set, run ${Chalk.green('rvm default <version>')}`);
        }
    }

    static runProxy() {
        console.log("Proxy not implemented yet");
    }
}

module.exports = RvmCliConfig;
