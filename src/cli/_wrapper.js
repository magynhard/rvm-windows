const File = require("ruby-nice/file");

const RvmCliTools = require('./_tools');
const RvmCliUse = require('./tasks/_use');
const RvmCliList = require('./tasks/_list');

class Wrapper {
    /**
     * Search for .ruby-version or ruby in Gemfile in the current folder or parent folders.
     *
     * If found, return its version, otherwise return current ruby.
     *
     * @param {string} path to check for ruby version
     */
    static getRubyVersionForPath(path) {
        const self = Wrapper;
        let version = RvmCliTools.getCurrentVersion();
        while (true) {
            let gem_file_version = null;
            if (File.isExisting(path + '/.ruby-version')) {
                version = File.read(path + '/.ruby-version');
                break;
            } else if (File.isExisting(path + '/Gemfile') && File.read(path + '/Gemfile').match(/ruby\s*["']([0-9\.]+)['"]/gm)) {
                const gem_file_content = File.read(path + '/Gemfile');
                const ruby_version_regex = /ruby\s*["']([0-9\.]+)['"]/gm;
                const gem_version = ruby_version_regex.exec(gem_file_content)[1].trim()
                version = gem_version;
                break;
            } else {
                path = File.getDirname(path);
                if (path === "") {
                    break;
                }
            }
        }
        version = version.trim();
        if (RvmCliTools.startsWithNumber(version)) {
            version = `ruby-${version}`;
        }
        return version.trim();
    }

    static hasRubyEnvCommand(version, command) {
        const self = Wrapper;
        if (RvmCliTools.versions().includes(version)) {
            const bin_path = RvmCliTools.config().envs[version] + '/bin';
            return File.isExisting(`${bin_path}/${command}.bat`) ||
                File.isExisting(`${bin_path}/${command}.cmd`) ||
                File.isExisting(`${bin_path}/${command}.exe`)
        } else if (RvmCliTools.matchingVersion(version, RvmCliTools.versions())) {
            return true;
        } else {
            return false;
        }
    }

    static getRubyEnvCommandPath(version, command) {
        const self = Wrapper;
        if (RvmCliTools.versions().includes(version) || RvmCliTools.matchingVersion(version, RvmCliTools.versions())) {
            let final_version = version;
            if (!RvmCliTools.versions().includes(version) && RvmCliTools.matchingVersion(version, RvmCliTools.versions())) {
                final_version = RvmCliTools.matchingVersion(version, RvmCliTools.versions());
            }
            const bin_path = RvmCliTools.config().envs[final_version] + '/bin';
            let final_command = null;
            ['exe', 'bat', 'cmd'].eachWithIndex((ext) => {
                let path = `${bin_path}/${command}.${ext}`;
                if (File.isExisting(path)) {
                    final_command = path;
                    return false;
                }
            });
            return final_command;
        } else {
            throw new Error(`Ruby version ${version} not found!`);
        }
    }

    static getPathOfMatchingRubyVersion(version) {
        const matching_version = RvmCliTools.matchingVersion(version, RvmCliTools.versions());
        if(matching_version) {
            return RvmCliTools.config().envs[matching_version];
        }
    }
}

module.exports = Wrapper;