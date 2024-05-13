#!/usr/bin/env node

const FileUtils = require('ruby-nice/file-utils');
const Chalk = require('chalk');
const {execSync} = require('child_process');

const RvmCliTools = require('./../_tools');
const RvmCliUninstall = require('./_uninstall');
const RvmCliInstall = require('./_install');
const RvmCliVersion = require('./_version');


class RvmCliGet {

    static runGet() {
        const self = RvmCliGet;
        const command = "npm install -g rvm-windows@latest";
        const old_version = RvmCliVersion.getFullVersion();
        console.log(`Current version of rvm-windows is ${Chalk.green(old_version)}.`);
        console.log(`Updating to its latest version ... ${Chalk.green(command)} ... please wait ...`);
        execSync(command);
        const new_version = RvmCliVersion.getFullVersion();
        if(old_version === new_version) {
            console.log(`Nothing to do. rvm-windows is already up to date!`);
        } else {
            console.log(`Update complete. New version is ${Chalk.green(new_version)}.`);
        }
    }
}

module.exports = RvmCliGet;


