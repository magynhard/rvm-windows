#!/usr/bin/env node

const FileUtils = require('ruby-nice/file-utils');
const Chalk = require('chalk');

const RvmCliTools = require('./../_tools');
const RvmCliUninstall = require('./_uninstall');
const RvmCliInstall = require('./_install');


class RvmCliReinstall {

    static runReinstall(version) {
        const self = RvmCliReinstall;
        version = version || process.argv[3];
        if (!version) {
            console.error(`No version given. Run ${Chalk.green('rvm reinstall <version>')}, for example: ${Chalk.green('rvm reinstall ruby-3.2.2')}`);
            process.exit(1);
        }
        const install_dir = RvmCliTools.config().envs[version];
        if(install_dir) {
            RvmCliUninstall.runUninstall(version);
            RvmCliInstall.runInstall(version);
        } else {
            // reuse Uninstall error only, not running install
            RvmCliUninstall.runUninstall(version);
        }
    }
}

module.exports = RvmCliReinstall;


