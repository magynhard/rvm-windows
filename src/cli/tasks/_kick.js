#!/usr/bin/env node

const Chalk = require('chalk');

const RvmCliTools = require('./../_tools');
const RvmCliUse = require('./_use');


class RvmCliKick {

    static runKick(version) {
        const self = RvmCliKick;
        version = version || process.argv[3];
        if (!version) {
            console.error(`No version given. Run ${Chalk.green('rvm kick <version>')}, for example: ${Chalk.green('rvm kick ruby-3.2.2')}`);
            process.exit(1);
        }
        // prefix ruby- if it starts with number
        if (RvmCliTools.startsWithNumber(version)) {
            version = "ruby-" + version;
        }
        const install_dir = RvmCliTools.config().envs[version];
        if(install_dir) {
            console.log(`Remove ${Chalk.green(version)} from list ... please wait ...`);
            let config = RvmCliTools.config();
            delete config.envs[version];
            RvmCliTools.writeRvmConfig(config);
            console.log(`The environment ${Chalk.red(version)} has been successfully removed from the list!`);
            console.log("");
            RvmCliUse.fixDefaultAndCurrent();
        } else {
            console.error(`Given version ${Chalk.red(version)} not found. To list all installed versions, run ${Chalk.green("rvm list")}.`);
        }
    }
}

module.exports = RvmCliKick;


