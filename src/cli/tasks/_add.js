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
    static runAdd(path) {
        const self = RvmCliAdd;
        path = RvmCliTools.normalizePath(path) || File.normalizePath(process.argv.slice(3).join(' ')); // get paths with spaces as well - put all from position 3 together
        path = path.replace("/bin/ruby.exe","");
        if(Object.values(RvmCliTools.config().envs).includes(path)) {
            console.log(`Ruby at ${Chalk.green(File.expandPath(path))} is already added. Nothing to do.`);
        } else {
            if(!Dir.isExisting(path)) {
                console.log(`Could not find path ${Chalk.red(File.expandPath(path))}`);
            } else {
                let new_config = RvmCliTools.config();
                new_config.envs['add'] = path;
                RvmCliTools.writeRvmConfig(new_config);
                RvmCliFix.fixEnvironmentVersions();
                RvmCliFix.fixWrapperFiles();
                console.log(`Added Ruby environment at ${Chalk.green(File.expandPath(path))}.`);
            }
        }
    }
}

module.exports = RvmCliAdd;
