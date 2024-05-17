#!/usr/bin/env node

const RvmCliUse = require('../cli/tasks/_use');
const RvmCliList = require('../cli/tasks/_list');
const RvmCliTools = require('../cli/_tools');
const Wrapper = require('../cli/_wrapper');

const cwd = process.argv[2];
const command = process.argv[3].split(".")[0];

let version = Wrapper.getRubyVersionForPath(cwd);

// proxy
let proxy_var = "";
const proxy = RvmCliTools.config().proxy;
if(proxy.enabled) {
    console.log(proxy.hostname)
} else {
    console.log("");
}