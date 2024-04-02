#!/usr/bin/env node
const {execSync} = require('child_process');
const Fs = require('fs');
const File = require('ruby-nice/file');

var RvmCliTools = require('./../_tools');

class RvmCliFix {
    static fix() {
        const self = RvmCliFix;
        self.fixExistingEnvironmentPaths();
        self.fixMissingEnvironmentPaths();
        self.fixEnvironmentVersions();
    }

    /**
     * Check and fix environment paths in .rvm.json
     */
    static fixExistingEnvironmentPaths() {
        let new_config = RvmCliTools.config();
        RvmCliTools.config().envs.eachWithIndex((version, path) => {
            const final_path = `${path}/bin/ruby.exe`;
            if(!File.isExisting(final_path)) {
                delete new_config.envs[version];
            } else {
                new_config.envs[version] = File.normalizePath(path);
            }
        });
        RvmCliTools.writeRvmConfig(new_config);
    }

    /**
     * Check for ruby installations not listed in config envs
     */
    static fixMissingEnvironmentPaths() {
        const self = RvmCliFix;
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

    /**
     * Check and fix environment versions in .rvm.json
     */
    static fixEnvironmentVersions() {
        let new_config = RvmCliTools.config();
        RvmCliTools.config().envs.eachWithIndex((version, path) => {
            const final_path = `${path}/bin/ruby.exe`;
            if(!File.isExisting(final_path)) {
                delete new_config.envs[version];
            } else {
                const result = execSync(`${final_path} --version`);
                const pure_version = result.toString().match(/ruby\s+([0-9\.]+)/gm)[0].split(" ")[1];
                if(pure_version) {
                    const old_path = new_config.envs[version];
                    delete new_config.envs[version];
                    new_config.envs[`ruby-${pure_version}`] = File.normalizePath(old_path);
                } else {
                    throw new Error(`Could not detect version from: ${result}`);
                }
            }
        });
        RvmCliTools.writeRvmConfig(new_config);
    }
}

module.exports = RvmCliFix;
