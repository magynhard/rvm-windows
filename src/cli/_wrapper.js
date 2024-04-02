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
        } else {
            throw new Error(`Ruby version ${version} not found!`);
        }
    }

    static getRubyEnvCommandPath(version, command) {
        const self = Wrapper;
        if (RvmCliList.versions().includes(version)) {
            const bin_path = RvmCliTools.config().envs[version] + '/bin';
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
            throw new Error(`Ruby version ${version} not found!`);
        }
    }
}

module.exports = Wrapper;