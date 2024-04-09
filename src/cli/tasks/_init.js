#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const {execSync} = require('child_process');

const child_process = require('child_process');


var RvmCliTools = require('./../_tools');
var RvmCliFix = require('./../tasks/_fix');
var RvmCliScan = require('./../tasks/_scan');

class RvmCliInit {
    /**
     * Ensure that the wrapper directory for ruby is set
     *
     * @param {boolean} silent do not display a message on success/error
     */
    static ensureWrapperPathEnvIsSet(silent = false) {
        const self = RvmCliInit;
        const rvm_wrapper_path = File.expandPath(`${File.getHomePath()}/.rvm/wrapper`);
        let user_path = self.getUserPath();
        // add only if not already added
        if(user_path && !user_path.startsWith(rvm_wrapper_path)) {
            user_path = user_path.replace(";" + rvm_wrapper_path, ""); // remove existing path
            // add at the beginning of path env variable
            const add_path_cmd = `setx PATH "${rvm_wrapper_path};${user_path}"`;
            let stdout3 = null;
            try {
                execSync(add_path_cmd, {encoding: 'utf-8', stdio: 'ignore'});
                if (!silent) {
                    console.log(`Added path successfully!`);
                }
                self.reloadCmd(`${rvm_wrapper_path};${user_path}`);
            } catch (e) {
                if (!silent) {
                    console.error(`Error when adding path: ${e.message}`);
                }
            }
        } else {
            if(!silent) {
                console.warn(`Path is already added!`);
            }
        }
    }

    static reloadCmd(path) {
        child_process.spawn(
            // With this variable we know we use the same shell as the one that started this process
            "C:\\Windows\\System32\\cmd.exe",
            {
                stdio: 'inherit',
                // set path environment variable
                env: { ...process.env, PATH: path },
            },
        );
    }

    static getUserPath() {
        const get_user_path_batch = RvmCliTools.rvmRootPath() + '/src/tools/path/get_user_path.bat';
        return execSync(get_user_path_batch, {encoding: 'utf-8'});
    }

    static initAfterInstall(force = false) {
        const self = RvmCliInit;
        if(!File.isExisting(RvmCliTools.rvmConfigPath()) || force) {
            RvmCliFix.fixConfig();
            self.ensureWrapperPathEnvIsSet(true);
            RvmCliScan.scan();
            console.log(`RVM has been initialized and is ready to use! (Open terminals will need to be restarted to reload PATH environment variable)`);
        }
    }
}

module.exports = RvmCliInit;


