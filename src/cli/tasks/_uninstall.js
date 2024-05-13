#!/usr/bin/env node

const FileUtils = require('ruby-nice/file-utils');
const Chalk = require('chalk');
const Dir = require('ruby-nice/dir');

const RvmCliTools = require('./../_tools');
const RvmCliUse = require("./_use");


class RvmCliUninstall {

    static runUninstall(version) {
        const self = RvmCliUninstall;
        let final_version = version || process.argv[3];
        if (!final_version) {
            console.error(`No version given. Run ${Chalk.green('rvm uninstall <version>')}, for example: ${Chalk.green('rvm uninstall ruby-3.2.2')}`);
            process.exit(1);
        }
        // prefix ruby- if it starts with number
        if (RvmCliTools.startsWithNumber(final_version)) {
            final_version = "ruby-" + final_version;
        }
        const install_dir = File.expandPath(RvmCliTools.config().envs[final_version]);
        if(install_dir && Dir.isExisting(install_dir)) {
            console.log(`Uninstalling ${Chalk.green(final_version)} from ${Chalk.red(install_dir)} ... please wait ...`);
            FileUtils.rmRf(install_dir);
            let config = RvmCliTools.config();
            delete config.envs[final_version];
            RvmCliTools.writeRvmConfig(config);
            console.log(`The environment ${Chalk.red(final_version)} has been successfully removed!`);
            console.log("");
            if(!version) {
                RvmCliUse.fixDefaultAndCurrent();
            }
        } else {
            console.error(`Given version ${Chalk.red(final_version)} not found. To list all installed versions, run ${Chalk.green("rvm list")}.`);
        }
    }
}

module.exports = RvmCliUninstall;


