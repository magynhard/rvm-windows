#!/usr/bin/env node
const {execSync} = require('child_process');
const Fs = require('fs');
const File = require('ruby-nice/file');
const Dir = require('ruby-nice/dir');
require('ruby-nice/object');
const FileUtils = require('ruby-nice/file-utils');

var RvmCliTools = require('./../_tools');
var RvmCliFix = require('./_fix');

class RvmCliScan {
    static scan() {
        const self = RvmCliScan;
        self.scanMissingEnvironmentPaths();
        RvmCliFix.fixEnvironmentVersions();
        RvmCliFix.fixWrapperFiles();
    }

    /**
     * Check for ruby installations not listed in config envs
     */
    static scanMissingEnvironmentPaths() {
        const self = RvmCliScan;
        const paths = execSync(`where ruby`).toString();
        let new_config = RvmCliTools.config();
        paths.split("\n").eachWithIndex((path, i) => {
            path = File.normalizePath(path.trim());
            path = path.replace("/bin/ruby.exe", "");
           if(!path.includes(`${File.getHomePath()}/.rvm/`)) {
               if(!Object.values(new_config).includes(path)) {
                   new_config.envs["unknown_" + i] = File.normalizePath(path);
               }
           }
        });
        RvmCliTools.writeRvmConfig(new_config);
    }
}

module.exports = RvmCliScan;
