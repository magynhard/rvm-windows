#!/usr/bin/env node

const FileUtils = require('ruby-nice/file-utils');
const Chalk = require('chalk');

const RvmCliTools = require('./../_tools');
const RvmCliUninstall = require('./_uninstall');
const RvmCliInstall = require('./_install');
const Dir = require("ruby-nice/dir");
const File = require("ruby-nice/file");
const RvmCliUse = require("./_use");
const RvmCliList = require("./_list");


class RvmCliUpgrade {

    static runUpgrade(from_version, to_version) {
        const self = RvmCliUpgrade;
        from_version = from_version || process.argv[3];
        to_version = to_version || process.argv[4];
        RvmCliList.runListAll(true).then((releases) => {
            // prefix ruby- if it starts with number
            if (RvmCliTools.startsWithNumber(from_version)) {
                from_version = "ruby-" + from_version;
            }
            if(!to_version) {
                const from_without_patch = from_version.split(".").slice(0,2).join(".");
                to_version = RvmCliTools.matchingVersion(from_without_patch, releases);
            }
            if (!from_version) {
                console.error(`${Chalk.red("No version given.")} Run ${Chalk.green('rvm upgrade <version>')}, for example: ${Chalk.green('rvm upgrade ruby-3.2.0')}`);
                process.exit(1);
            }
            // prefix ruby- if it starts with number
            if (RvmCliTools.startsWithNumber(to_version)) {
                to_version = "ruby-" + to_version;
            }
            const install_dir = RvmCliTools.config().envs[from_version];
            if(install_dir) {
                console.log(`Upgrading ${Chalk.green(from_version)} to ${Chalk.green(to_version)} ...`);
                console.log();
                const install_dir = RvmCliTools.config().envs[from_version];
                RvmCliInstall.runInstall(to_version, install_dir);
            } else {
                console.error(`Given version ${Chalk.red(from_version)} not found. To list all installed versions, run ${Chalk.green("rvm list")}.`);
            }
        });
    }
}

module.exports = RvmCliUpgrade;


