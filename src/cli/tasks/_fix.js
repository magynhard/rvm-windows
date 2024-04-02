#!/usr/bin/env node
const {execSync} = require('child_process');
const Fs = require('fs');
const File = require('ruby-nice/file');
const Dir = require('ruby-nice/dir');
require('ruby-nice/object');
const FileUtils = require('ruby-nice/file-utils');

var RvmCliTools = require('./../_tools');

class RvmCliFix {
    static fix() {
        const self = RvmCliFix;
        self.fixConfig();
        self.fixExistingEnvironmentPaths();
        self.fixMissingEnvironmentPaths();
        self.fixEnvironmentVersions();
        self.fixWrapperFiles();
    }

    static fixConfig() {
        const self = RvmCliFix;
        // create config if not available
        if(!File.isExisting(RvmCliTools.rvmConfigPath())) {
            FileUtils.mkdirP(File.getDirname(RvmCliTools.rvmConfigPath()));
            FileUtils.copy(RvmCliTools.rvmConfigTemplatePath(), RvmCliTools.rvmConfigPath());
        } else {
            try {
                JSON.parse(RvmCliTools.rvmConfigPath());
            } catch (e) {
                // recreate config if broken
                FileUtils.rmRf(RvmCliTools.rvmConfigPath());
                FileUtils.copy(RvmCliTools.rvmConfigTemplatePath(), RvmCliTools.rvmConfigPath());
            }
        }
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

    /**
     * Remove and recreate all wrapper files based on the available ruby environments
     */
    static fixWrapperFiles() {
        const self = RvmCliFix;
        const wrapper_path = File.getHomePath() + '/.rvm/wrapper';
        FileUtils.rmRf(wrapper_path);
        FileUtils.mkdirP(wrapper_path);
        RvmCliTools.config().envs.eachWithIndex((version, path) => {
            const env_bin_files = Dir.glob(path + '/bin/*.*');
            env_bin_files.eachWithIndex((file) => {
                const file_name = File.getBasename(file);
                if(file_name.endsWith('.bat')) {
                    if(!File.isExisting(wrapper_path + '/' + file_name)) {
                        FileUtils.copy(RvmCliTools.rvmBatchTemplatePath(), wrapper_path + '/' + file_name);
                    }
                } else if(file_name.endsWith('.exe')) {
                    if(!File.isExisting(wrapper_path + '/' + file_name)) {
                        FileUtils.copy(RvmCliTools.rvmBatchTemplatePath(), wrapper_path + '/' + file_name + '.bat');
                        FileUtils.copy(RvmCliTools.rvmBatchTemplatePath(), wrapper_path + '/' + File.getBasename(file_name,'.exe') + '.bat');
                    }
                } else if(file_name.endsWith('.cmd')) {
                    if(!File.isExisting(wrapper_path + '/' + file_name)) {
                        FileUtils.copy(RvmCliTools.rvmBatchTemplatePath(), wrapper_path + '/' + file_name + '.bat');
                        FileUtils.copy(RvmCliTools.rvmBatchTemplatePath(), wrapper_path + '/' + File.getBasename(file_name, '.cmd') + '.bat');
                    }
                }
            });
        });
    }
}

module.exports = RvmCliFix;
