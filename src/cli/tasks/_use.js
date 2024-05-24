#!/usr/bin/env node

const {execSync} = require('child_process');
const Chalk = require('chalk');

const File = require('ruby-nice/file');
var RvmCliTools = require('./../_tools');
var RvmCliFix = require('./_fix');
var RvmCliScan = require('./_scan');
var RvmCliAdd = require('./_add');
var RvmCliConfig = require('./_config');

class RvmCliUse {
    static runUse(version) {
        const self = RvmCliUse;
        version = version || process.argv[3];
        let param = process.argv[4];
        if(version?.startsWith("--")) {
            version = param;
        }
        if(RvmCliTools.startsWithNumber(param) && process.argv[3].startsWith("--")) {
            param = process.argv[3];
        }
        if(!version) {
            console.error(`${Chalk.red("No version given.")} Run ${Chalk.green('rvm use <version>')}, for example: ${Chalk.green('rvm use ruby-3.2.2')}`);
            process.exit(1);
        }
        else if(version === "default") {
            version = RvmCliTools.config().default || RvmCliTools.config().envs[0];
        }
        else if(version === "system") {
            version = self.addAndGetSystemVersion();
            if(!version) {
                console.log(Chalk.red(`No system ruby found!`) + ` You can manually add a system ruby by running ${Chalk.green("rvm add <path>")}, e.g. ${Chalk.green("rvm add C:\\Ruby-3.2.2x64")}.`);
                process.exit(1);
            }
        }
        // prefix ruby- if it starts with number
        if(RvmCliTools.startsWithNumber(version)) {
            version = "ruby-" + version;
        }
        let match = RvmCliTools.matchingVersion(version);
        if(match) {
            RvmCliTools.setCurrentVersion(match);
            console.log(`Using ${Chalk.green(match)} from ${Chalk.green(File.expandPath(RvmCliTools.config().envs[match]))} ...`);
            RvmCliFix.fixWrapperFiles();
            if(param && param === "--default") {
                RvmCliTools.setDefaultVersion(version);
            }
        } else {
            console.error(`No version for ${Chalk.red(version)} available! Run ${Chalk.green('rvm list')} to show available versions.`);
        }
    }


    /**
     * Check of currently set "default" and "current" versions are available or set at all.
     * Then reset if needed.
     */
    static fixDefaultAndCurrent() {
        const self = RvmCliTools;
        execSync(`rvm fix`);
        const new_version = Object.keys(RvmCliTools.config().envs)[0];
        const default_version = RvmCliTools.config().default;
        const current_version = self.getCurrentVersion();
        if (!RvmCliTools.config().envs[current_version]) {
            if (RvmCliTools.config().envs[default_version]) {
                RvmCliUse.runUse(default_version);
            } else if(new_version) {
                RvmCliUse.runUse(new_version);
            }
        }
        if(!RvmCliTools.config().envs[default_version]) {
            if (RvmCliTools.config().envs[current_version]) {
                RvmCliConfig.runDefault(current_version);
            } else if(new_version) {
                RvmCliConfig.runDefault(new_version);
            }
        }
    }

    /**
     * Add and return system version or undefined if no system version found
     * @return {string|undefined}
     */
    static addAndGetSystemVersion() {
        console.log(`Scanning for system rubies ...\n`);
        let paths = RvmCliScan.scanMissingEnvironmentPaths(false);
        const system_paths = paths.filter((p => !p.includes("ProgramData\\rvm") && !p.includes("ProgramData/rvm")));
        if(system_paths && system_paths.length > 0) {
            console.log("Found the following system rubies:");
            console.log(system_paths.map(e => ` - ${Chalk.green(e)}`).join("\n"));
            console.log();
        }
        let first_system_path = system_paths[0];
        if(first_system_path) {
            RvmCliAdd.runAdd(first_system_path);
            return RvmCliFix.getRubyVersionFromRubyPath(first_system_path);
        }
    }
}

module.exports = RvmCliUse;


