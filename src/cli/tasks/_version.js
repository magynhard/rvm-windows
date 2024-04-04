#!/usr/bin/env node

const fs = require('fs');
const File = require('ruby-nice/file');

var RvmCliTools = require('./../_tools');

class RvmCliVersion {
    static version() {
        const self = RvmCliVersion;
        console.log(self.getFullVersion());
    }

    static getVersion() {
        const self = RvmCliVersion;
        const package_json = self.getPackageJson();
        return `${package_json.version}`;
    }

    static getFullVersion() {
        const self = RvmCliVersion;
        const package_json = self.getPackageJson();
        return `${package_json.name} ${package_json.version}`;
    }

    static getPackageJson() {
        return JSON.parse(File.read(__dirname + '/../../../package.json'));
    }
}

module.exports = RvmCliVersion;
