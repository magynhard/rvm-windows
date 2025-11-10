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
        } else if(["p", "proxy"].includes(command)) {
            self.runProxy();
        } else if(["da", "data"].includes(command)) {
            self.runDataPath();
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
    
    static printDataPath() {
        const data_path = RvmCliTools.getRvmDataDir();
        console.log(`RVM data directory at ${Chalk.green(data_path)}`);
    }

    static runDataPath() {
        const self = RvmCliConfig;
        let config = RvmCliTools.config();
        const path = process.argv[4];
        if(path) {
            config.rvm_data_dir = File.expandPath(path);
            RvmCliTools.writeRvmConfig(config);
        }
        self.printDataPath();
    }

    static runProxy(hostname) {
        const self = RvmCliConfig;
        hostname = (hostname || process.argv[4] || "").trim();
        if(hostname) {
            let config = RvmCliTools.config();
            if(!config.proxy || typeof config.proxy !== "object") {
                config.proxy = {};
            }
            if(hostname === "delete") {
                config.proxy.hostname = "";
                console.log(`Removed proxy configuration!`);
            } else if(hostname === "enable") {
                config.proxy.enabled = true;
                console.log(`Enabled proxy!`);
                let proxy = config.proxy;
                console.log(`${proxy.hostname} [${proxy.enabled ? Chalk.green('enabled') : Chalk.red('disabled')}]`);
            } else if(hostname === "disable") {
                config.proxy.enabled = false;
                console.log(`Disabled proxy!`);
                let proxy = config.proxy;
                console.log(`${proxy.hostname} [${proxy.enabled ? Chalk.green('enabled') : Chalk.red('disabled')}]`);
            } else {
                if(!hostname.startsWith("http")) {
                    hostname = "http://" + hostname;
                }
                config.proxy.hostname = hostname;
                config.proxy.enabled = true;
                console.log(`Set proxy ${Chalk.green(hostname)} ... [${config.proxy.enabled ? Chalk.green('enabled') : Chalk.red('disabled')}]`)
            }
            RvmCliTools.writeRvmConfig(config);
        } else {
            let proxy = RvmCliTools.config().proxy;
            if(!proxy.hostname) {
                console.log(`No proxy configured!`);
            } else {
                console.log(`${proxy.hostname} [${proxy.enabled ? Chalk.green('enabled') : Chalk.red('disabled')}]`);
            }
        }
    }
}

module.exports = RvmCliConfig;
