#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const { execSync } = require('child_process');

var RvmCliTools = require('./../_tools');
var Wrapper = require('./../_wrapper');
const Chalk = require('chalk');

const ruby_env_path = Wrapper.getPathOfMatchingRubyVersion(Wrapper.getRubyVersionForPath(process.cwd()));

class RvmCliKit {

    static kit() {
        const self = RvmCliKit;
        console.log("Installing a bunch of helpful dependencies for building native gems ...\n");
        self.dependencies.x64.eachWithIndex((dep) => {
            console.log(`Install pacman dependency ${Chalk.green(dep)} ...`);
            self.installPacmanDependency(dep);
        });
        self.runAdditionalFixes();
        console.log("\nInstallation complete!");
    }

    static installPacmanDependency(dependency) {
        const self = RvmCliKit;
        dependency = dependency.split(" ")[0]; // security
        execSync(`ridk exec sh -c "pacman --noconfirm -S ${dependency}"`)
    }

    static runAdditionalFixes() {
        const self = RvmCliKit;
        self.after_commands.eachWithIndex((cmd) => {
           console.log(`Run fix command ${Chalk.green(cmd)}`);
           execSync(cmd);
        });
    }
}

RvmCliKit.dependencies = {
    'x64': [
        'mingw-w64-x86_64-postgresql',
        'mingw-w64-ucrt-x86_64-libmariadbclient',
    ]
}

RvmCliKit.after_commands = [
    `gem install mysql2 --platform=ruby -- --with-mysql-dir="${ruby_env_path}/msys64/ucrt64"`
]

module.exports = RvmCliKit;


