#!/usr/bin/env node
const {execSync} = require('child_process');
const Fs = require('fs');
const File = require('ruby-nice/file');
const Dir = require('ruby-nice/dir');
const Chalk = require('chalk');
require('ruby-nice/object');
const FileUtils = require('ruby-nice/file-utils');

var RvmCliTools = require('./../_tools');

class RvmCliFix {
    static runFix() {
        const self = RvmCliFix;
        console.log(`Fix several issues that could have happened ...`);
        RvmCliTools.killRunningMsysProcesses();
        console.log(`Fix config ...`);
        self.fixConfig();
        console.log(`Fix existing environment paths ...`);
        self.fixExistingEnvironmentPaths();
        console.log(`Fix environment versions ...`);
        self.fixEnvironmentVersions();
        console.log(`Fix wrapper files ...`);
        self.fixWrapperFiles();
        console.log(`Fixing finished!\n`);
        console.log(`If you still have trouble, you might try to run ${Chalk.green("rvm init")} to reinit rvm-windows itself!`);
    }

    static fixConfig() {
        const self = RvmCliFix;
        // create config if not available
        if(!File.isExisting(RvmCliTools.rvmConfigPath())) {
            FileUtils.mkdirP(File.getDirname(RvmCliTools.rvmConfigPath()));
            FileUtils.copy(RvmCliTools.rvmConfigTemplatePath(), RvmCliTools.rvmConfigPath());
        } else {
            try {
                JSON.parse(File.read(RvmCliTools.rvmConfigPath()));
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
     * Check and fix environment versions in .rvm.json
     */
    static fixEnvironmentVersions() {
        const self = RvmCliFix;
        let new_config = RvmCliTools.config();
        RvmCliTools.config().envs.eachWithIndex((version, path) => {
            const final_path = `${path}/bin/ruby.exe`;
            if(!File.isExisting(final_path)) {
                delete new_config.envs[version];
            } else {
                const result = execSync(`"${final_path}" --version`, {encoding: 'utf-8'});
                const pure_version = self.getRubyVersionFromRubyPath(path);
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

    static getRubyVersionFromRubyPath(ruby_path) {
        const self = RvmCliFix;
        let final_path = `${ruby_path}/bin/ruby.exe`;
        const result = execSync(`"${final_path}" --version`, {encoding: 'utf-8'});
        const pure_version = result.toString().match(/ruby\s+([0-9\.]+)/gm)[0].split(" ")[1];
        return pure_version;
    }

    static getRubyPlatformFromRubyPath(ruby_path) {
        const self = RvmCliFix;
        let final_path = `${ruby_path}/bin/ruby.exe`;
        const result = execSync(`"${final_path}" --version`, {encoding: 'utf-8'});
        let pure_platform = result.toString().match(/ruby\s+[0-9\.]+[^\[]+\[([^\[]+)\]/gm)[0].trim().split(" ").getLast();
        // remove brackets
        pure_platform = pure_platform.substring(1,pure_platform.length-1);
        return pure_platform;
    }

    /**
     * Remove and recreate all wrapper files based on the available ruby environments
     */
    static fixWrapperFiles() {
        const self = RvmCliFix;
        let node_path = process.argv[0];
        if(!node_path.endsWith('node.exe')) {
            throw new Error(`Can not determine node js runtime!`);
        }
        // escape spaces in path segments
        // @example
        // C:\Program Files\node\node.exe => C:\"Program Files"\node\node.exe
        //
        node_path = node_path.split("\\").map((el) => {
            if(el.includes(" ")) {
                return `"${el}"`;
            } else {
                return el;
            }
        }).join("\\");
        const rvm_root_dir = RvmCliTools.rvmRootPath();
        const wrapper_path = RvmCliTools.getRvmDataDir() + '/wrapper';
        FileUtils.rmRf(wrapper_path);
        FileUtils.mkdirP(wrapper_path);
        RvmCliTools.config().envs.eachWithIndex((version, path) => {
            const env_bin_files = Dir.glob(path + '/bin/*.*');
            let parsed_template = File.read(RvmCliTools.rvmBatchTemplatePath()).replace('{{node_js_runtime_path}}', node_path).replace('{{rvm_root_dir}}', rvm_root_dir);
            env_bin_files.eachWithIndex((file) => {
                const file_name = File.getBasename(file);
                if(file_name.endsWith('.bat')) {
                    if(!File.isExisting(wrapper_path + '/' + file_name)) {
                        File.write( wrapper_path + '/' + file_name, parsed_template);
                    }
                } else if(file_name.endsWith('.exe')) {
                    if(!File.isExisting(wrapper_path + '/' + file_name)) {
                        File.write( wrapper_path + '/' + file_name + '.bat', parsed_template);
                        File.write( wrapper_path + '/' + File.getBasename(file_name,'.exe') + '.bat', parsed_template);
                    }
                } else if(file_name.endsWith('.cmd')) {
                    if(!File.isExisting(wrapper_path + '/' + file_name)) {
                        File.write( wrapper_path + '/' + file_name + '.bat', parsed_template);
                        File.write( wrapper_path + '/' + File.getBasename(file_name,'.cmd') + '.bat', parsed_template);
                    }
                }
            });
        });
    }
}

module.exports = RvmCliFix;
