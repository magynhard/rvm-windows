#!/usr/bin/env node

const fs = require('fs');
const Os = require('os');
const File = require('ruby-nice/file');
const { execSync } = require('child_process');

const RvmCliVersion = require('./_version');
const RvmCliTools = require('./../_tools');

class RvmCliInfo {
    static runInfo() {
        const self = RvmCliInfo;
        const ruby_version = RvmCliTools.getCurrentVersion();
        const rvm_version = RvmCliVersion.getVersion();
        const full_ruby_version = execSync(`"${File.expandPath(RvmCliTools.config().envs[RvmCliTools.getCurrentVersion()]+"/bin/ruby.exe")}" --version`, {encoding: 'utf-8'}).toString().trim();
        console.log();
        console.log(ruby_version);
        console.log();
        console.log("  system:");
        console.log("    uname:       ", Os.version(), "(" + Os.release() + ")", "[" + Os.arch() + "]");
        console.log("    name:        ", Os.version());
        console.log("    version:     ", Os.release());
        console.log("    architecture:", Os.arch());
        console.log("    bash:        ", execSync(`(dir 2>&1 *\`|echo CMD);&<# rem #>echo ($PSVersionTable).PSEdition`).toString().trim());
        console.log();
        console.log("  rvm:");
        console.log("    version:     ", rvm_version);
        console.log("    path:        ", RvmCliTools.getRvmDataDir());
        console.log();
        console.log("  ruby:");
        console.log("    interpreter: ", "ruby");
        console.log("    version:     ", RvmCliTools.getCurrentRawVersion());
        console.log("    date:        ", full_ruby_version.match(/\(([^\s]+).*\)/)[1]);
        console.log("    platform:    ", full_ruby_version.match(/\[([^\]]+)\]/)[1]);
        console.log("    patchlevel:  ", full_ruby_version.match(/\(([^\]]+)\)/)[1]);
        console.log("    full_version:", full_ruby_version);
        console.log();
        console.log("  homes:");
        console.log("    ruby: ", File.expandPath(RvmCliTools.config().envs[RvmCliTools.getCurrentVersion()]));
    }
}

module.exports = RvmCliInfo;
