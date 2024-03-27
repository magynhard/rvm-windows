#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const { execSync } = require('child_process');

var RvmCliTools = require('./../_tools');

class RvmCliSetup {
    static ensurePathEnvIsSet() {
        const rvm_wrapper_path = File.expandPath(`${File.getHomePath()}/.rvm/wrapper`);
        const addPathEnvironmentVariable = () => {
            // Befehl zum Hinzufügen des Pfads zur PATH-Umgebungsvariable am Anfang
            const add_path_cmd = `setx PATH "${rvm_wrapper_path};%PATH%"`;
            let stdout3 = null;
            try {
                stdout3 = execSync(add_path_cmd, { encoding: 'utf-8' });
                console.log(`Added path successfully!`);
            } catch (e) {
                console.error(`Error when adding path: ${e.message}`);
            }
        }
        addPathEnvironmentVariable();
    }
}

module.exports = RvmCliSetup;


