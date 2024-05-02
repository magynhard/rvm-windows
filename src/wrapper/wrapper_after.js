#!/usr/bin/env node

const RvmCliFix = require('../cli/tasks/_fix');
const Wrapper = require('../cli/_wrapper');

const cwd = process.argv[2];
const command = process.argv[3].split(".")[0];

let version = Wrapper.getRubyVersionForPath(cwd);

// Refresh wrapper files after installing gems, to ensure new commands are available
if(command === "gem" || command === "bundle") {
    console.log("Updating wrapper files ...");
    RvmCliFix.fixWrapperFiles();
    console.log("done");
}