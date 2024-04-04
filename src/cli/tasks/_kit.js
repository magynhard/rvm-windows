#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const { execSync } = require('child_process');

var RvmCliTools = require('./../_tools');
var RvmCliFix = require('./../tasks/_fix');
var Wrapper = require('./../_wrapper');
const Chalk = require('chalk');

const ruby_env_path = Wrapper.getPathOfMatchingRubyVersion(Wrapper.getRubyVersionForPath(process.cwd()));

class RvmCliKit {

    static kit() {
        const self = RvmCliKit;
        console.log("Installing a bunch of helpful dependencies for building native gems ...\n");
        const platform = RvmCliFix.getRubyPlatformFromRubyPath(ruby_env_path);
        if(platform && self.dependencies[platform]) {
            self.dependencies[platform].eachWithIndex((dep) => {
                console.log(`Install pacman dependency ${Chalk.green(dep)} ...`);
                self.installPacmanDependency(dep);
            });
            self.after_commands[platform].eachWithIndex((cmd) => {
                console.log(`Run fix command ${Chalk.green(cmd)}`);
                execSync(cmd, {encoding: 'utf-8'});
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
        `gem install mysql2 --platform=ruby -- --with-mysql-dir="${ruby_env_path}/msys64/ucrt64"`
    ],
    'x64-mingw32': [
        `gem install mysql2 --platform=ruby -- --with-mysql-dir="${ruby_env_path}/msys64/mingw64"`
    ]
}

module.exports = RvmCliKit;


