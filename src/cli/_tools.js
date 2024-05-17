#!/usr/bin/env node

const Chalk = require('chalk');
const CommandLineUsage = require('command-line-usage');
const { execSync } = require('child_process');
const Prompt = require('prompt-sync')();
const Path = require('path');
const Fs = require('fs');
const Fse = require('fs-extra');
const RvmCliVersion = require('./tasks/_version');
const File = require('ruby-nice/file');
const Dir = require('ruby-nice/dir');
const System = require('ruby-nice/system');
const Typifier = require('typifier');
const {fetch, ProxyAgent} = require("undici");

class RvmCliTools {

    static logo() {
        const version_label = Chalk.reset.green(`  ${RvmCliVersion.getVersion()}  `);
        // ASCII-Font: Calvin S
        // Sub title font: Source Code Pro Bold
        return Chalk.redBright.bold("\n    \n" +
            "      ██████╗  ██╗   ██╗ ███╗   ███╗     \n" +
            "      ██╔══██╗ ██║   ██║ ████╗ ████║     \n" +
            "      ██████╔╝ ██║   ██║ ██╔████╔██║     \n" +
            "      ██╔══██╗ ╚██╗ ██╔╝ ██║╚██╔╝██║     \n" +
            "      ██║  ██║  ╚████╔╝  ██║ ╚═╝ ██║     \n" +
            "      ╚═╝  ╚═╝   ╚═══╝   ╚═╝     ╚═╝     \n" +
            "                                       \n" + Chalk.bold.white(
            "      Ruby Version Manager 4 Windows    \n") +
            `              ` + ` ${version_label}      ` +
            "                                         "
        );
    }

    /**
     * Colorize specified key values inside Object with chalk
     *
     * @param {Object} hash
     * @param {string|Array<string>} keys or key
     * @param {string} color
     * @returns {Object}
     * @private
     */
    static colorizeValues(hash, keys, color) {
        const self = RvmCliTools;
        if (typeof keys === 'string') {
            keys = [keys];
        }
        Object.keys(hash).forEach(h_key => {
            if (keys.includes(h_key)) {
                hash[h_key] = Chalk[color](hash[h_key]);
            }
            if (typeof hash[h_key] === 'object') {
                self.colorizeValues(hash[h_key], keys, color);
            }
        });
        return hash;
    }

    /**
     * Prompt user for input
     *
     * @param {string} question to ask the user for
     * @param {Array<string>} options set only valid options (optional)
     * @param {string} preselected_option preselected option
     * @param {boolean} mandatory if true, option can not be asked with empty string
     * @returns {string} input
     */
    static cliQuestion(question, options, preselected_option, mandatory = false) {
        const self = RvmCliTools;
        if(self.first_question) {
            if(preselected_option) {
                console.log('  Preselection in [' + Chalk.green('brackets') + '] can be confirmed with ENTER.\n');
            }
            self.first_question = false;
        }
        let default_string = null;
        if(preselected_option) {
            default_string = ' [' + Chalk.green(preselected_option) + ']';
        } else {
            default_string = '';
        }
        let input = preselected_option;
        while(true) {
            input = Prompt('  ' + question + default_string + ': ');
            if(input === '') {
                input = preselected_option !== null ? preselected_option : input;
            }
            if(options) {
                if(options && typeof options[0] !== "undefined") {
                    if(options.includes(input)) {
                        break;
                    } else {
                        // CTRL+C
                        if(input === null) {
                            process.exit(1);
                        }
                        // invalid input value
                        self.printLine(Chalk.red(`\n  Invalid input '${input}'.`) + `\n  Valid options are: ${options.map((e) => { return Chalk.green(e); }).join(' | ')}\n`);
                    }
                } else {
                    break;
                }
            } else if(mandatory && !input) {
                // CTRL+C
                if(input === null) {
                    process.exit(1);
                }
                self.printLine(Chalk.red('Mandatory option, please enter a valid text.' + JSON.stringify(input)));
            } else {
                // CTRL+C
                if(input === null) {
                    process.exit(1);
                }
                break;
            }
        }
        return input || '';
    }

    static getRvmDataDir() {
        const self = RvmCliTools;
        let dir = self.config().rvm_data_dir || self.getDefaultRvmDataDir();
        // cut slash or backslash at the end
        if(dir.endsWith("/") || dir.endsWith("\\")) {
            dir = dir.substring(0, dir.length-1);
        }
        return dir;
    }

    static getDefaultRvmDataDir() {
        return File.expandPath("C:/ProgramData/rvm");
    }

    static startsWithNumber(content) {
        if(content) {
            return `${parseInt(content[0])}` === content[0];
        } else {
            return false;
        }
    }

    /**
     * Return  matching version from given versions or installed environments.
     *
     * Given version can be incomplete. Then it will return the highest matching version.
     *
     * @example
     *
     * matchingVersion("ruby-3")
     * // => "ruby-3.2.2"
     *
     * @param {string} version
     * @param {Array<string>} versions
     * @returns {*}
     */
    static matchingVersion(version, versions) {
        const self = RvmCliTools;
        let match = null;
        versions = versions ?? RvmCliTools.versions();
        // direct match
        if(versions.includes(version)) {
            return version;
        } else {
            let split = version.split(".");
            // minor match
            if(split.length === 2) {
                const minor_version = split[0] + "." + split[1];
                let version_match = null;
                versions.sort(RvmCliTools.versionSort).reverse().eachWithIndex((v) => {
                    if(v.startsWith(`${minor_version}.`)) {
                        version_match = v;
                        return false; // break
                    }
                });
                if(version_match) {
                    return version_match;
                }
            } else if(split.length === 1) {
                let version_match = null;
                versions.sort(RvmCliTools.versionSort).reverse().eachWithIndex((v) => {
                    if(v.startsWith(`${split[0]}.`)) {
                        version_match = v;
                        return false;
                    }
                });
                if(version_match) {
                    return version_match;
                }
            }
        }
    }

    static versions() {
        const self = RvmCliTools;
        return Object.keys(self.config().envs).sort(self.versionSort);
    }

    static rawVersions() {
        const self = RvmCliTools;
        return self.versions().map(e => e.replace("ruby-", ""));
    }

    static setCurrentVersion(version) {
        const self = RvmCliTools;
        if(version && process.env.RVM_SESSION) {
            const file_name = File.expandPath(RvmCliTools.rvmSessionsDir() + '/' + process.env.RVM_SESSION);
            File.write(file_name, version);
        }
    }

    static killRunningMsysProcesses() {
        console.log(`Kill running msys processes ...`);
        const commands = [
            `taskkill /f /im "msys2.exe"`,
            `taskkill /f /im "ucrt64.exe"`,
            `taskkill /f /im "mingw64.exe"`,
            `taskkill /f /im "mingw32.exe"`,
            `taskkill /f /im "clang64.exe"`,
            `taskkill /f /im "clang32.exe"`,
            `taskkill /f /im "msys2_shell.cmd"`,
            `taskkill /f /im "autorebase.cmd"`,
            `taskkill /f /fi "MODULES eq msys-2.0.dll"`,
        ];
        commands.eachWithIndex((cmd) => {
           try {
               execSync(cmd, {stdio: 'ignore'});
           } catch (e) {
               // we catch it, if command could not be stopped or found
           }
        });
    }

    static getCurrentVersion() {
        let rvm_session = process.env.RVM_SESSION;
        if(rvm_session) {
            const session_file = File.expandPath(RvmCliTools.rvmSessionsDir() + '/' + process.env.RVM_SESSION);
            if(File.isExisting(session_file)) {
                return File.read(session_file);
            }
        }
        return RvmCliTools.getDefaultVersion();
    }

    /**
     * Get current version without ruby- prefix
     */
    static getCurrentRawVersion() {
        const self = RvmCliTools;
        return self.getCurrentVersion().replace("ruby-","");
    }



    static setDefaultVersion(version) {
        const self = RvmCliTools;
        if(!version) {
            console.error(`${Chalk.red("No version given.")} Run ${Chalk.green('rvm default <version>')}, for example: ${Chalk.green('rvm default ruby-3.2.2')}`);
            process.exit(1);
        }
        // prefix ruby- if it starts with number
        if(RvmCliTools.startsWithNumber(version)) {
            version = "ruby-" + version;
        }
        let match = RvmCliTools.matchingVersion(version);
        if(match) {
            let config = RvmCliTools.config();
            config.default = match;
            RvmCliTools.writeRvmConfig(config);
            console.log(`Set default ${Chalk.green(match)} from ${Chalk.green(RvmCliTools.config().envs[match])} ...`);
        } else {
            console.error(`No version for ${Chalk.red(version)} available! Run ${Chalk.green('rvm list')} to show available versions.`);
        }
    }

    static getDefaultVersion() {
        return RvmCliTools.config().default;
    }

    /**
     * Print line with trailing new line
     *
     * @param {string} text
     */
    static printLine(text) {
        if(!text) {
            text = '';
        }
        console.log('  ' + text);
    }

    /**
     * Print line without trailing new line
     *
     * @param {string} text
     */
    static print(text) {
        if(!text) {
            text = '';
        }
        process.stdout.write('  ' + text);
    }

    static uniqArray(array) {
        return [...new Set(array)];
    }

    /**
     * Get only the deepest dirs, without dirs between
     * @param {Array<String>} dirs to filter
     */
    static filterDeepDirsOnly(dirs) {
        let filtered = [];
        dirs.forEach((dir, i) => {
            if(dirs.filter((e) => { return e.includes(dir); }).length === 1) {
                filtered.push(dir);
            }
        });
        return filtered;
    }

    static rvmRootPath() {
        const self = RvmCliTools;
        return File.expandPath(Path.resolve(__dirname + '/../../'));
    }

    static projectRootPath() {
        const self = RvmCliTools;
        return File.expandPath(process.cwd());
    }

    static readRvmConfig() {
        const self = RvmCliTools;
        return File.read(self.rvmConfigPath());
    }

    static config() {
        const self = RvmCliTools;
        return JSON.parse(self.readRvmConfig());
    }

    /**
     * @param {string, Object} content as String or parsed JSON object
     */
    static writeRvmConfig(content) {
        const self = RvmCliTools;
        if(Typifier.isObject(content)) {
            content = JSON.stringify(content, null, 2);
        }
        File.write(self.rvmConfigPath(), content, { encoding: "utf8" });
    }

    static rvmConfigPath() {
        const self = RvmCliTools;
        return File.expandPath(`${File.getHomePath()}/.rvm.json`);
    }

    static rvmSessionsDir() {
        const self = RvmCliTools;
        return File.expandPath(`${File.getHomePath()}/.rvm/sessions`);
    }

    static rvmConfigTemplatePath() {
        const self = RvmCliTools;
        return self.rvmRootPath() + '/src/templates/.rvm.json';
    }

    static rvmBatchTemplatePath() {
        const self = RvmCliTools;
        return self.rvmRootPath() + '/src/templates/wrapper_template.bat';
    }

    static makeDir(dir) {
        Fs.mkdirSync(dir, { recursive: true });
    }

    static makeDirOfFile(file) {
        const self = RvmCliTools;
        let final_dir = File.expandPath(Path.dirname(file));
        Fs.mkdirSync(final_dir, { recursive: true });
    }

    static readFile(path, encoding = 'utf8') {
        if(!encoding) {
            encoding = undefined;
        }
        return Fs.readFileSync(path, encoding).toString();
    }

    static writeFile(path, content) {
        const self = RvmCliTools;
        self.makeDirOfFile(path);
        return Fs.writeFileSync(path, content);
    }

    static copyFile(src, dest) {
        const self = RvmCliTools;
        self.makeDirOfFile(dest);
        Fs.copyFileSync(src, dest);
    }

    static copy(src, dest) {
        const self = RvmCliTools;
        Fse.copySync(src, dest);
    }

    static isDir(path) {
        const self = RvmCliTools;
        try {
            const stat = Fs.lstatSync(path);
            return stat.isDirectory();
        } catch (e) {
            return false;
        }
    }

    static isFile(path) {
        const self = RvmCliTools;
        try {
            const stat = Fs.lstatSync(path);
            return stat.isFile();
        } catch (e) {
            return false;
        }
    }

    static pathExists(path) {
        const self = RvmCliTools;
        try {
            const stat = Fs.lstatSync(path);
            return true;
        } catch (e) {
            return false;
        }
    }

    /**
     * Ensure path is divided by slashes / and not back slashes \
     * to ensure compatibility with MS Windows
     *
     * @param {String} path
     */
    static normalizePath(path) {
        return path.replace(/\\/g,'/');
    }

    /**
     * Delete file or directory
     *
     * @param {String} path
     */
    static removePath(path) {
        Fs.rmSync(path, { recursive: true, force: true });
    }

    static escapeRegExp(string) {
        return string.replace(/[$+.*?^(){}|[\]\\]/g, '\\$&');
    }

    static fetchWithProxy(url, opts) {
        const self = RvmCliTools;
        let final_opts = {};
        if(RvmCliTools.config().proxy?.enabled && RvmCliTools.config().proxy?.hostname) {
            final_opts = {
                ...opts,
                dispatcher: new ProxyAgent({
                    uri: process.env.HTTPS_PROXY || self.config().proxy.hostname,
                    keepAliveTimeout: 10,
                    keepAliveMaxTimeout: 10,
                }),
            };
        } else {
            final_opts = opts;
        }
        return fetch(url, final_opts);
    }

    /**
     * Sorting string version in format 1.2.3
     *
     * @example
     *      ["1.10.3","2.1.3","1.2.3"].sort(.versionSort)
     *      // => ["1.2.3","1.10.3","2.1.3"]
     *
     * @param {string} a
     * @param {string} b
     * @returns {number}
     */
    static versionSort(a, b) {
        a = a.replace("ruby-","");
        b = b.replace("ruby-","");
        if(parseInt(a.split(".")[0]) > parseInt(b.split(".")[0])) {
            return 1;
        } else if(parseInt(a.split(".")[0]) < parseInt(b.split(".")[0])) {
            return -1
        } else { // same, level 2
            if(parseInt(a.split(".")[1] || 0) > parseInt(b.split(".")[1] || 0)) {
                return 1;
            } else if(parseInt(a.split(".")[1] || 0) < parseInt(b.split(".")[1] || 0)) {
                return -1
            } else { // same level 3
                if(parseInt(a.split(".")[2] || 0) > parseInt(b.split(".")[2] || 0)) {
                    return 1;
                } else if(parseInt(a.split(".")[2] || 0) < parseInt(b.split(".")[2] || 0)) {
                    return -1
                } else {
                    return 0;
                }
            }
        }
    }
}

RvmCliTools.PACKAGE_JSON_FILE_PATH = RvmCliTools.projectRootPath() + '/package.json';

RvmCliTools.first_question = true;
RvmCliTools.cached_config = null;

RvmCliTools.SECTIONS = {};
RvmCliTools.SECTIONS.not_inside_valid_project = [
    {
        header: 'Invalid project directory',
        content: [
            '{red You can run this command at the root directory of a project with rvm configuration only.}',
            '',
            `Current directory:\n {green ${RvmCliTools.projectRootPath()}}`
        ]
    }
];

//
// pre patch, until new ruby-nice is imported
//

Object.defineProperty(String.prototype, 'scan', {
    /**
     * Matching the pattern (which may be a Regexp or a String).
     *
     * For each match, a result is generated and either added to the result array. If the pattern contains no groups, each individual result consists of the matched string.
     * If the pattern contains groups, each individual result is itself an array containing one entry per group.
     *
     * @example
     *      let a = "cruel world";
     *
     *      a.scan(/\w+/)
     *      // => ["cruel", "world"]
     *
     *      a.scan(/.../)
     *      // => ["cru", "el ", "wor"]
     *
     *      a.scan(/(...)/)
     *      // => [["cru"], ["el "], ["wor"]]
     *
     *      a.scan(/(..)(..)/)
     *      // => [["cr", "ue"], ["l ", "wo"]]
     *
     * @param {string|RegExp} pattern
     *
     */
    value: function scan(pattern) {
        if(typeof pattern === "undefined") {
            throw new Error(`ArgumentError (wrong number of arguments (given 0, expected 1))`);
        }
        const escapeRegExp = (string) => {
            return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
        };
        if(Typifier.isString(pattern)) {
            pattern = new RegExp(escapeRegExp(pattern),'gm');
        } else {
            // add mandatory global option
            let new_flags = pattern.flags;
            if(!new_flags.includes("g")) new_flags += "g";
            pattern = new RegExp(pattern.source, new_flags);
        }
        const contains_groups = !!(pattern.source.match(/(^\(|[^\\]\()/));
        if(!contains_groups) {
            return [...this.matchAll(pattern)].map(e => e[0]);
        }
        const original_index = pattern.lastIndex;
        pattern.lastIndex = 0;
        let results = [];
        let res = null;
        while(res = pattern.exec(this)) {
            results.push(res.slice(1));
            if(pattern.lastIndex === 0) {
                break;
            }
        }
        pattern.lastIndex = original_index;
        return results;
    }
});




module.exports = RvmCliTools;
