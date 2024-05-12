#!/usr/bin/env node
const {execSync} = require('child_process');
const Fs = require('fs');
const File = require('ruby-nice/file');
const Dir = require('ruby-nice/dir');
require('ruby-nice/object');
const FileUtils = require('ruby-nice/file-utils');

var RvmCliTools = require('./../_tools');
var RvmCliFix = require('./_fix');
var RvmCliList = require('./_list');

class RvmCliScan {
    static scan() {
        const self = RvmCliScan;
        console.log(`Scanning for installed rubies and add them to list ...\n`);
        self.scanMissingEnvironmentPaths();
        RvmCliFix.fixEnvironmentVersions();
        RvmCliFix.fixWrapperFiles();
        RvmCliList.listVerbose();
    }

    /**
     * Check for ruby installations not listed in config envs
     */
    static scanMissingEnvironmentPaths() {
        const self = RvmCliScan;
        try {
            let paths = execSync(`chcp 65001 > NUL & where ruby`, { stdio: 'pipe'}).toString();
            paths = paths.split("\n");
            const rvm_paths = Dir.glob(RvmCliTools.getRvmDataDir() + '/envs/*');
            paths = paths.concat(rvm_paths);
            paths.concat(Dir.glob("C:\\Program Files\\Ruby*"));
            paths.concat(Dir.glob("C:\\Ruby*"));
            let new_config = RvmCliTools.config();
            paths.eachWithIndex((path, i) => {
                if(path) {
                    path = File.normalizePath(path.trim());
                    path = path.replace("/bin/ruby.exe", "");
                    if(!Object.values(new_config).includes(path)) {
                        new_config.envs["unknown_" + i] = File.normalizePath(path);
                    }
                }
            });
            RvmCliTools.writeRvmConfig(new_config);
        } catch (e) {
            // no installed ruby available
        }
    }
}

module.exports = RvmCliScan;
