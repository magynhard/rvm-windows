#!/usr/bin/env node
const {execSync} = require('child_process');
const Fs = require('fs');
const File = require('ruby-nice/file');
const Dir = require('ruby-nice/dir');

var RvmCliTools = require('./../_tools');
const Chalk = require("chalk");
const RvmCliUse = require("./_use");
const RvmCliFix = require("./_fix");

class RvmCliAdd {
    static runAdd() {
        const self = RvmCliAdd;
        let path = File.normalizePath(process.argv.slice(3).join(' '));
        path = path.replace("/bin/ruby.exe","");
        if(Object.values(RvmCliTools.config().envs).includes(path)) {
            console.log(`Ruby at ${Chalk.green(path)} is already added. Nothing to do.`);
        } else {
            if(!Dir.isExisting(path)) {
                console.log(`Could not find path ${Chalk.red(path)}`);
            } else {
                let new_config = RvmCliTools.config();
                new_config.envs['add'] = path;
                RvmCliTools.writeRvmConfig(new_config);
                RvmCliFix.fixEnvironmentVersions();
                RvmCliFix.fixWrapperFiles();
                console.log(`Added Ruby environment at ${Chalk.green(path)}.`);
            }
        }
    }
}

module.exports = RvmCliAdd;
