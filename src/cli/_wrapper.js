const File = require("ruby-nice/file");

const RvmCliTools = require('./_tools');
const RvmCliUse = require('./tasks/_use');
const RvmCliList = require('./tasks/_list');

class Wrapper {
    /**
     * Search for .ruby-version in the current folder or parent folders.
     *
     * If found, return its version, otherwise return current ruby.
     *
     * @param {string} path to check for ruby version
     */
    static getRubyVersionForPath(path) {
        const self = Wrapper;
        let version = RvmCliTools.config().current;
        while (true) {
            if (File.isExisting(path + '/.ruby-version')) {
                version = File.read(path + '/.ruby-version');
                break;
            } else {
                path = File.getDirname(path);
                if (path === "") {
                    break;
                }
            }
        }
        if (RvmCliUse._startsWithNumber(version)) {
            version = `ruby-${version}`;
        }
        return version;
    }

    static hasRubyEnvCommand(version, command) {
        const self = Wrapper;
        if (RvmCliList.versions().includes(version)) {
            const bin_path = RvmCliTools.config().envs[version] + '/bin';
            return File.isExisting(`${bin_path}/${command}.bat`) ||
                File.isExisting(`${bin_path}/${command}.cmd`) ||
                File.isExisting(`${bin_path}/${command}.exe`)
        } else if(RvmCliUse._matchingVersion(version, RvmCliList.versions())) {
            return true;
        }
        else {
            return false;
        }
    }

    static getRubyEnvCommandPath(version, command) {
        const self = Wrapper;
        if (RvmCliList.versions().includes(version) || RvmCliUse._matchingVersion(version, RvmCliList.versions())) {
            let final_version = version;
            if(!RvmCliList.versions().includes(version) && RvmCliUse._matchingVersion(version, RvmCliList.versions())) {
                final_version = RvmCliUse._matchingVersion(version, RvmCliList.versions());
            }
            const bin_path = RvmCliTools.config().envs[final_version] + '/bin';
            let final_command = null;
            ['exe','bat','cmd'].eachWithIndex((ext) => {
                let path = `${bin_path}/${command}.${ext}`;
                if(File.isExisting(path)) {
                    final_command = path;
                    return false;
                }
            });
            return final_command;
        } else {
            throw new Error(`Ruby version ${final_version} not found!`);
        }
    }
}

module.exports = Wrapper;