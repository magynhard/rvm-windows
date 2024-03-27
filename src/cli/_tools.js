#!/usr/bin/env node

const Chalk = require('chalk');
const CommandLineUsage = require('command-line-usage');
const Prompt = require('prompt-sync')();
const Path = require('path');
const Fs = require('fs');
const Fse = require('fs-extra');
const RvmCliVersion = require('./tasks/_version');
const File = require('ruby-nice/file');
const Dir = require('ruby-nice/dir');
const Typifier = require('typifier');

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
        return self.normalizePath(Path.resolve(__dirname + '/../../'));
    }

    static projectRootPath() {
        const self = RvmCliTools;
        return self.normalizePath(process.cwd());
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

    static makeDir(dir) {
        Fs.mkdirSync(dir, { recursive: true });
    }

    static makeDirOfFile(file) {
        const self = RvmCliTools;
        let final_dir = self.normalizePath(Path.dirname(file));
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
     * Ensure path is divided by slashes / and not back slahes \
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
