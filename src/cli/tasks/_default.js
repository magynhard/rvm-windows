#!/usr/bin/env node

const Chalk = require('chalk');

var RvmCliUse = require('./_use');

class RvmCliDefault {
    static runDefault() {
        const self = RvmCliDefault;
        RvmCliUse.runUse("default");
    }
}

module.exports = RvmCliDefault;


