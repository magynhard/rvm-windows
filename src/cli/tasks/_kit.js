#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const FileUtils = require('ruby-nice/file-utils');
const { execSync } = require('child_process');

var RvmCliTools = require('./../_tools');
var RvmCliFix = require('./../tasks/_fix');
var Wrapper = require('./../_wrapper');
const Chalk = require('chalk');

const ruby_env_path = Wrapper.getPathOfMatchingRubyVersion(Wrapper.getRubyVersionForPath(process.cwd())).replaceAll("\\","/");

class RvmCliKit {

    static runKit() {
        const self = RvmCliKit;
        console.log("Installing a bunch of helpful dependencies for building native gems ...\n");
        self.installRidkTools();
        console.log("Updating pacman dependencies ...\n");
        const platform = RvmCliFix.getRubyPlatformFromRubyPath(ruby_env_path);
        if(platform && self.dependencies[platform]) {
            self.dependencies[platform].eachWithIndex((dep) => {
                console.log(`Installing pacman dependency ${Chalk.green(dep)} ...`);
                self.installPacmanDependency(dep);
            });
            self.after_commands[platform].eachWithIndex((cmd) => {
                let final_command = cmd;
                let patch_version = null;
                if((patch_version = Object.keys(self.latest_supported_versions).find(e => RvmCliTools.getCurrentRawVersion().startsWith(e)))) {
                    RvmCliKit.latest_supported_versions[patch_version].eachWithIndex((gem, version) => {
                        final_command = final_command.replace(`gem install ${gem} `, `gem install ${gem} -v ${version} `);
                    });
                }
                console.log(`Running fix command ${Chalk.green(final_command)} ...`);
                execSync(final_command, {encoding: 'utf-8'});
            });
            console.log("\nInstallation complete!");
        } else {
            console.error(`Platform invalid or not supported: ${platform}`);
        }
    }

    static installPacmanDependency(dependency) {
        const self = RvmCliKit;
        dependency = dependency.split(" ")[0]; // security
        execSync(`chcp 65001 > NUL && ridk exec sh -c "pacman --noconfirm -S ${dependency}"`, {encoding: 'utf-8'})
    }

    static installRidkTools() {
        console.log(`Ensure ridk tools are installed ... please wait ...`);
        const vs = RvmCliTools.getCurrentRawVersion();
        // ridk install 1 2 3 still works fine on ruby 2.6.x / 2.7.x / 3.0.x, but not on 2.4.x / 2.5.x
        // so we install and copy msys64 from ruby 3.0.x when using ruby < 3
        if(vs.startsWith("2.4.") || vs.startsWith("2.5.")) {
            const old_version = RvmCliTools.getCurrentVersion();
            if(!RvmCliTools.matchingVersion("ruby-2.6")) {
                console.log(`Installing ${Chalk.green("ruby-2.6.x")} to patch current ${Chalk.green(RvmCliTools.getCurrentVersion())} with its msys64 ... please wait ...`);
                execSync(`rvm install 2.6`);
                execSync(`rvm use ${old_version}`);
            }
            let matching_version = RvmCliTools.matchingVersion("ruby-2.6");
            console.log(`Patch current version ${Chalk.green(RvmCliTools.getCurrentVersion())} with msys from ${Chalk.green(matching_version)} ... please wait ...`);
            const source_path = RvmCliTools.config().envs[matching_version];
            const target_path = RvmCliTools.config().envs[RvmCliTools.getCurrentVersion()];
            FileUtils.rmRf(File.expandPath(target_path + '/msys64'));
            FileUtils.cp_r(source_path + '/msys64', target_path + '/msys64');
            console.log("Patch complete!");
            console.log("");
            console.log("Updating dev tools by ridk ... please wait ...");
            console.log("");
        }
        execSync(`chcp 65001 > NUL && ridk install 1 2 3`, {encoding: 'utf-8'});
        execSync(`ridk exec pacman --noconfirm -Sy`); // fixes pg install on 2.4 / 2.5
    }
}

RvmCliKit.dependencies = {
    'x64-mingw-ucrt': [
        'mingw-w64-ucrt-x86_64-postgresql',
        'mingw-w64-ucrt-x86_64-libmariadbclient',
    ],
    'x64-mingw32': [
        'mingw-w64-x86_64-postgresql',
        'mingw-w64-x86_64-libmariadbclient',
    ]
}

RvmCliKit.after_commands = {
    'x64-mingw-ucrt': [
        `gem install mysql2 --platform=ruby -- --with-mysql-dir="${ruby_env_path}/msys64/ucrt64"`,
        `gem install pg --platform=ruby -- --with-mysql-dir="${ruby_env_path}/msys64/ucrt64"`,
        `gem install eventmachine --platform=ruby -- --with-mysql-dir="${ruby_env_path}/msys64/ucrt64"`,
        `gem install nokogiri --platform=ruby -- --with-mysql-dir="${ruby_env_path}/msys64/ucrt64"`,
    ],
    'x64-mingw32': [
        `gem install mysql2 --platform=ruby -- --with-mysql-dir="${ruby_env_path}/msys64/mingw64"`,
        `gem install pg --platform=ruby -- --with-mysql-dir="${ruby_env_path}/msys64/mingw64"`,
        `gem install eventmachine --platform=ruby -- --with-mysql-dir="${ruby_env_path}/msys64/mingw64"`,
        `gem install nokogiri --platform=ruby -- --with-mysql-dir="${ruby_env_path}/msys64/mingw64"`,
    ]
}

/*
    some gems end their support at specific versions, that need to be installed explicitly if using that ruby version
 */
RvmCliKit.latest_supported_versions = {
    '2.4': {
        'pg': '1.2.3',
        'nokogiri': '1.10.10',
    },
    '2.7': {
        'nokogiri': '1.15.6',
    },
}

module.exports = RvmCliKit;


