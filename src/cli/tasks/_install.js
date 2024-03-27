#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const { execSync } = require('child_process');

var RvmCliTools = require('./../_tools');

class RvmCliInstall {
    /**
     * Ensure that the wrapper directory for ruby is set
     *
     * @param {boolean} silent do not display a message on success/error
     */
    static install() {
        console.log("INSTALL");
    }
}

module.exports = RvmCliInstall;


