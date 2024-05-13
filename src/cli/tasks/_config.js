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
        const config_path = RvmCliTools.rvmConfigPath();
        console.log(`RVM configuration at ${Chalk.green(config_path)}`);
        console.log()
        console.log(JSON.stringify(RvmCliTools.config(),null, 2));
    }
}

module.exports = RvmCliConfig;
