#!/usr/bin/env node

const Chalk = require('chalk');

var RvmCliUse = require('./_use');

class RvmCliSystem {
    static runSystem() {
        const self = RvmCliSystem;
        RvmCliUse.runUse("system");
    }
}

module.exports = RvmCliSystem;


