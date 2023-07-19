#!/usr/bin/env node

const fs = require('fs');
const File = require('ruby-nice/file');

var GroboCliTools = require('./../_tools');

class GroboCliVersion {
    static version() {
        const self = GroboCliVersion;
        console.log(self.getFullVersion());
    }

    static getVersion() {
        const self = GroboCliVersion;
        const package_json = self.getPackageJson();
        return `${package_json.version}`;
    }

    static getFullVersion() {
        const self = GroboCliVersion;
        const package_json = self.getPackageJson();
        return `${package_json.name} ${package_json.version} @ ${package_json.date}`;
    }

    static getPackageJson() {
        return JSON.parse(File.read(__dirname + '/../../../package.json'));
    }
}

module.exports = GroboCliVersion;
