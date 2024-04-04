#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const {execSync} = require('child_process');

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
        const rvm_wrapper_path = File.expandPath(`${File.getHomePath()}/.rvm/wrapper`);
        // add at the beginning of path env variable
        const add_path_cmd = `setx PATH "${rvm_wrapper_path};%PATH%"`;
        // we also add explicitly to current session, so the commands will be available instantly
        const add_tmp_path_cmd = `set "PATH=${rvm_wrapper_path};%PATH%"`;
        let stdout3 = null;
        try {
            execSync(add_path_cmd, {encoding: 'utf-8', stdio: 'ignore'});
            execSync(add_tmp_path_cmd, {encoding: 'utf-8', stdio: 'ignore'});
            if (!silent) {
                console.log(`Added path successfully!`);
            }
        } catch (e) {
            if (!silent) {
                console.error(`Error when adding path: ${e.message}`);
            }
        }
    }

    static initAfterInstall(force = false) {
        const self = RvmCliInit;
        if(!File.isExisting(RvmCliTools.rvmConfigPath()) || force) {
            RvmCliFix.fixConfig();
            self.ensureWrapperPathEnvIsSet();
            RvmCliScan.scan();
            console.log(`RVM has been initialized after the first run! Reopen your terminal `);
        }
    }
}

module.exports = RvmCliInit;


