#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const {execSync} = require('child_process');

var RvmCliTools = require('./../_tools');

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
        let stdout3 = null;
        try {
            stdout3 = execSync(add_path_cmd, {encoding: 'utf-8', stdio: 'ignore'});
            if (!silent) {
                console.log(`Added path successfully!`);
            }
        } catch (e) {
            if (!silent) {
                console.error(`Error when adding path: ${e.message}`);
            }
        }
    }
}

module.exports = RvmCliInit;


