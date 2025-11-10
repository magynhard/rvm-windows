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

    /**
     * Get the cool RVM logo string with version label
     *
     * @return {string}
     */
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

    /**
     * Get RVM data dir
     *
     * @example
     *
     * getRvmDataDir()
     * // => "C:/ProgramData/rvm"
     *
     * @return {string}
     */
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

    /**
     * Check if first character of given string is a number.
     *
     * @example
     *
     * startsWithNumber("3.2.1")
     * // => true
     *
     * startsWithNumber("ruby-3.2.1")
     * // => false
     *
     * @param {string} content
     * @return {boolean}
     *
     */
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

    /**
     * Get all installed ruby versions
     *
     * @example
     *
     * versions()
     * // => ["ruby-2.7.6", "ruby-3.0.4", "ruby-3.1.2", "ruby-3.2.2"]
     *
     * @return {string[]}
     */
    static versions() {
        const self = RvmCliTools;
        return Object.keys(self.config().envs).sort(self.versionSort);
    }

    /**
     * Get all installed ruby versions without ruby- prefix
     *
     * @example
     *
     * rawVersions()
     * // => ["2.7.6", "3.0.4", "3.1.2", "3.2.2"]
     *
     * @return {string[]}
     */
    static rawVersions() {
        const self = RvmCliTools;
        return self.versions().map(e => e.replace("ruby-", ""));
    }

    /**
     * Set current version for current session
     *
     * @example
     *
     * setCurrentVersion("ruby-3.2.2")
     *
     * @param {string} version
     */
    static setCurrentVersion(version) {
        const self = RvmCliTools;
        if(version && process.env.RVM_SESSION) {
            const file_name = File.expandPath(RvmCliTools.rvmSessionsDir() + '/' + process.env.RVM_SESSION);
            File.write(file_name, version);
        }
    }

    /**
     * Kill all running msys2 processes to be able to update msys2 installation
     */
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

    /**
     * Get current version for current session
     *
     * @example
     *
     * If current version is ruby-3.2.2
     *
     * getCurrentVersion()
     * // => "ruby-3.2.2"
     *
     * @returns {string}
     */
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
     * Get current version without ruby- prefix for current session
     *
     * @example
     *
     * If current version is ruby-3.2.2
     *
     * getCurrentRawVersion()
     * // => "3.2.2"
     *
     * @returns {string}
     */
    static getCurrentRawVersion() {
        const self = RvmCliTools;
        return self.getCurrentVersion().replace("ruby-","");
    }

    /**
     * Set default version
     *
     * @example
     *
     * // Set default to ruby-3.2.2, when only this version is installed
     * setDefaultVersion("ruby-3.2.2")
     * setDefaultVersion("3.2.2")
     * setDefaultVersion("3.2")
     * setDefaultVersion("3")
     *
     * @param version
     */
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

    /**
     * Get default version
     *
     * @example
     *
     * If default version is ruby-3.2.2
     *
     * getDefaultVersion()
     * // => "ruby-3.2.2"
     *
     * @return {string}
     */
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

    /**
     * Get unique values from array
     *
     * @example
     *
     * uniqArray([1,2,2,3,4,4,5])
     * // => [1,2,3,4,5]
     *
     * @param {Array} array
     * @return {Array<any>}
     */
    static uniqArray(array) {
        return [...new Set(array)];
    }

    /**
     * Get only the deepest dirs, without dirs between
     *
     * @example
     *
     * filterDeepDirsOnly([
     *   "a/b/c",
     *   "a/b",
     *   "a/b/c/d",
     *   "e/f",
     *   "e/f/g/h",
     *   "i/j"
     * ])
     * // => [
     * //      "a/b/c/d",
     * //      "e/f/g/h",
     * //      "i/j"
     * //    ]
     *
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

    /**
     * Get RVM root path
     *
     * @example
     *
     * rvmRootPath()
     * // => "C:/path/to/rvm-cli-windows"
     *
     * @return {string}
     */
    static rvmRootPath() {
        const self = RvmCliTools;
        return File.expandPath(Path.resolve(__dirname + '/../../'));
    }

    /**
     * Get "project" root path (current working directory)
     *
     * @example
     *
     * projectRootPath()
     * // => "C:/path/to/current/project"
     *
     * @return {string}
     */
    static projectRootPath() {
        const self = RvmCliTools;
        return File.expandPath(process.cwd());
    }

    /**
     * Read RVM config file
     *
     * @example
     *
     * readRvmConfig()
     * // => '{ "default": "ruby-3.2.2", "envs": { "ruby-3.2.2": "C:/Ruby32-x64" } }'
     *
     * @return {string}
     */
    static readRvmConfig() {
        const self = RvmCliTools;
        return File.read(self.rvmConfigPath());
    }

    /**
     * Get parsed RVM config file
     *
     * @example
     *
     * config()
     * // => { default: 'ruby-3.2.2', envs: { 'ruby-3.2.2': 'C:/Ruby32-x64' } }
     *
     * @return {Object}
     */
    static config() {
        const self = RvmCliTools;
        return JSON.parse(self.readRvmConfig());
    }

    /**
     * Write RVM config file
     *
     * @param {string, Object} content as String or parsed JSON object
     */
    static writeRvmConfig(content) {
        const self = RvmCliTools;
        if(Typifier.isObject(content)) {
            content = JSON.stringify(content, null, 2);
        }
        File.write(self.rvmConfigPath(), content, { encoding: "utf8" });
    }

    /**
     * Get RVM config file path
     *
     * @example
     *
     * rvmConfigPath()
     * // => "C:/Users/username/.rvm.json"
     *
     * @return {string}
     */
    static rvmConfigPath() {
        const self = RvmCliTools;
        return File.expandPath(`${File.getHomePath()}/.rvm.json`);
    }

    /**
     * Get RVM sessions dir path
     *
     * @example
     *
     * rvmSessionsDir()
     * // => "C:/Users/username/.rvm/sessions"
     *
     * @return {string}
     */
    static rvmSessionsDir() {
        const self = RvmCliTools;
        return File.expandPath(`${File.getHomePath()}/.rvm/sessions`);
    }

    /**
     * Get RVM config template file path
     *
     * @example
     *
     * rvmConfigTemplatePath()
     * // => "C:/path/to/rvm-cli-windows/src/templates/.rvm.json"
     *
     * @return {string}
     */
    static rvmConfigTemplatePath() {
        const self = RvmCliTools;
        return self.rvmRootPath() + '/src/templates/.rvm.json';
    }

    /**
     * Get RVM batch wrapper template file path
     *
     * @example
     *
     * rvmBatchTemplatePath()
     * // => "C:/path/to/rvm-cli-windows/src/templates/wrapper_template.bat"
     *
     * @return {string}
     */
    static rvmBatchTemplatePath() {
        const self = RvmCliTools;
        return self.rvmRootPath() + '/src/templates/wrapper_template.bat';
    }

    /**
     * Make directory recursively
     *
     * @example
     *
     * makeDir("C:/path/to/some/dir/with/many/new/folders")
     * // creates "C:/path/to/some/dir/with/many/new/folders"
     *
     * @param {string} dir
     */
    static makeDir(dir) {
        Fs.mkdirSync(dir, { recursive: true });
    }

    /**
     * Make directory of file recursively
     *
     * @example
     *
     * makeDirOfFile("C:/path/to/some/file.txt")
     * // creates "C:/path/to/some/"
     *
     * @param {string} file
     */
    static makeDirOfFile(file) {
        const self = RvmCliTools;
        let final_dir = File.expandPath(Path.dirname(file));
        Fs.mkdirSync(final_dir, { recursive: true });
    }

    /**
     * Read file content
     *
     * @example
     *
     * readFile("C:/path/to/some/file.txt", "utf8")
     * // => "file content ..."
     *
     * @param {string} path
     * @param {string} encoding='utf8'
     * @return {string}
     */
    static readFile(path, encoding = 'utf8') {
        if(!encoding) {
            encoding = undefined;
        }
        return Fs.readFileSync(path, encoding).toString();
    }

    /**
     * Write content to file
     *
     * @example
     *
     * writeFile("C:/path/to/some/file.txt", "file content ...")
     * // creates file with content
     *
     * @param {string} path
     * @param {string} content
     * @return {void}
     */
    static writeFile(path, content) {
        const self = RvmCliTools;
        self.makeDirOfFile(path);
        return Fs.writeFileSync(path, content);
    }

    /**
     * Copy file from source to destination
     *
     * @example
     *
     * copyFile("C:/path/to/source/file.txt", "C:/path/to/dest/file.txt")
     * // copies file from source to dest
     *
     * @param {string} src
     * @param {string} dest
     */
    static copyFile(src, dest) {
        const self = RvmCliTools;
        self.makeDirOfFile(dest);
        Fs.copyFileSync(src, dest);
    }

    /**
     * Copy directory from source to destination
     *
     * @example
     *
     * copy("C:/path/to/source/dir", "C:/path/to/dest/dir")
     * // copies directory from source to dest
     *
     * @param {string} src
     * @param {string} dest
     */
    static copy(src, dest) {
        const self = RvmCliTools;
        Fse.copySync(src, dest);
    }

    /**
     * Check if path is a directory
     *
     * @example
     *
     * isDir("C:/path/to/some/dir")
     * // => true
     * isDir("C:/path/to/some/file.txt")
     * // => false
     *
     * @param {string} path
     * @return {boolean}
     */
    static isDir(path) {
        const self = RvmCliTools;
        try {
            const stat = Fs.lstatSync(path);
            return stat.isDirectory();
        } catch (e) {
            return false;
        }
    }

    /**
     * Check if path is a file
     *
     * @example
     *
     * isFile("C:/path/to/some/file.txt")
     * // => true
     * isFile("C:/path/to/some/dir")
     * // => false
     *
     * @param {string} path
     * @return {boolean}
     */
    static isFile(path) {
        const self = RvmCliTools;
        try {
            const stat = Fs.lstatSync(path);
            return stat.isFile();
        } catch (e) {
            return false;
        }
    }

    /**
     * Check if path exists
     *
     * @example
     *
     * pathExists("C:/path/to/some/dir_or_file")
     * // => true
     * pathExists("C:/path/to/some/non_existing_dir_or_file")
     * // => false
     *
     * @param {string} path
     * @return {boolean}
     */
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
     * @example
     *
     * normalizePath("C:\\path\\to\\some\\dir_or_file")
     * // => "C:/path/to/some/dir_or_file"
     *
     * @param {string} path
     * @return {string}
     */
    static normalizePath(path) {
        return path.replace(/\\/g,'/');
    }

    /**
     * Delete file or directory
     *
     * @param {String} path
     * @return {void}
     */
    static removePath(path) {
        Fs.rmSync(path, { recursive: true, force: true });
    }

    /**
     * Escape string for usage in regular expression
     *
     * @example
     *
     * escapeRegExp("ruby-3.2.2 (x64-mingw32)")
     * // => "ruby\-3\.2\.2\ \(x64\-mingw32\)"
     *
     * @param {string} string
     * @return {string}
     */
    static escapeRegExp(string) {
        return string.replace(/[$+.*?^(){}|[\]\\]/g, '\\$&');
    }

    /**
     * Fetch with proxy support
     *
     * @param {string} url
     * @param {Object} opts of fetch
     * @return {Promise<Response>}
     */
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

module.exports = RvmCliTools;
