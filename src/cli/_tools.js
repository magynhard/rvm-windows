#!/usr/bin/env node

const chalk = require('chalk');
const commandLineUsage = require('command-line-usage');
const prompt = require('prompt-sync')();
const path = require('path');
const fs = require('fs');
const fse = require('fs-extra');
const GroboCliVersion = require('./tasks/_version');

class RvmCliTools {

    static logo() {
        const version_label = chalk.reset.redBright(`  ${GroboCliVersion.getVersion()}  `);
        // ASCII-Font: Calvin S
        // Sub title font: Source Code Pro Bold
        return chalk.redBright.bold("\n    \n" +
            "      ██████╗  ██╗   ██╗ ███╗   ███╗     \n" +
            "      ██╔══██╗ ██║   ██║ ████╗ ████║     \n" +
            "      ██████╔╝ ██║   ██║ ██╔████╔██║     \n" +
            "      ██╔══██╗ ╚██╗ ██╔╝ ██║╚██╔╝██║     \n" +
            "      ██║  ██║  ╚████╔╝  ██║ ╚═╝ ██║     \n" +
            "      ╚═╝  ╚═╝   ╚═══╝   ╚═╝     ╚═╝     \n" +
            "                                       \n" + chalk.bold.white(
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
                hash[h_key] = chalk[color](hash[h_key]);
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
                console.log('  Preselection in [' + chalk.redBright('brackets') + '] can be confirmed with ENTER.\n');
            }
            self.first_question = false;
        }
        let default_string = null;
        if(preselected_option) {
            default_string = ' [' + chalk.redBright(preselected_option) + ']';
        } else {
            default_string = '';
        }
        let input = preselected_option;
        while(true) {
            input = prompt('  ' + question + default_string + ': ');
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
                        self.printLine(chalk.red(`\n  Invalid input '${input}'.`) + `\n  Valid options are: ${options.map((e) => { return chalk.redBright(e); }).join(' | ')}\n`);
                    }
                } else {
                    break;
                }
            } else if(mandatory && !input) {
                // CTRL+C
                if(input === null) {
                    process.exit(1);
                }
                self.printLine(chalk.red('Mandatory option, please enter a valid text.' + JSON.stringify(input)));
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

    static isRunningInsideValidGroboProject() {
        const self = RvmCliTools;
        return fs.existsSync(self.GROBO_CONFIG_FILE_PATH);
    }

    static errorNotInsideValidGroboProject() {
        const self = RvmCliTools;
        const usage = commandLineUsage(self.SECTIONS.not_inside_valid_project);
        console.log(usage);
    }

    static invalidConfigPaths() {
        const self = RvmCliTools;
        const config = self.readProjectGroboConfig();
        let paths = [];
        if(config.development_server?.sass_watch_paths?.length || 0 > 0) {
            paths = paths.concat(config.development_server.sass_watch_paths.map(e => `app/${e}`));
        }
        let invalid_paths = [];
        paths.forEach((path) => {
            if(!fs.existsSync(path)) {
                invalid_paths.push(path);
            }
        });
        return invalid_paths;
    }

    static errorInvalidConfigPaths() {
        const self = RvmCliTools;
        const usage = commandLineUsage(self.SECTIONS.invalid_config_paths);
        console.log(usage);
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

    static groboRootPath() {
        const self = RvmCliTools;
        return self.normalizePath(path.resolve(__dirname + '/../../'));
    }

    static projectRootPath() {
        const self = RvmCliTools;
        return self.normalizePath(process.cwd());
    }

    static projectName() {
        const self = RvmCliTools;
        return self.readProjectPackageJson().name;
    }

    static readProjectGroboConfig(use_cache = true) {
        const self = RvmCliTools;
        let config = null;
        if(!self.cached_config || use_cache === false) {
            config = JSON.parse(self.readFile(self.GROBO_CONFIG_FILE_PATH));
            self.cached_config = Object.assign({}, config);
        } else {
            config = self.cached_config;
        }
        config = Object.assign(Object.assign({}, self.GROBO_CONFIG_DEFAULTS), config);
        if(!config.indexer) config.indexer = {};
        if(!config.indexer.ignored_files) config.indexer.ignored_files = [];
        return config;
    }

    static writeProjectGroboConfig(content) {
        const self = RvmCliTools;
        return self.writeFile(self.GROBO_CONFIG_FILE_PATH, JSON.stringify(content, null, 2));
    }

    static readProjectPackageJson() {
        const self = RvmCliTools;
        return JSON.parse(self.readFile(self.PACKAGE_JSON_FILE_PATH));
    }

    static writeProjectPackageJson(content) {
        const self = RvmCliTools;
        return self.writeFile(self.PACKAGE_JSON_FILE_PATH, JSON.stringify(content, null, 2));
    }

    static makeDir(dir) {
        fs.mkdirSync(dir, { recursive: true });
    }

    static makeDirOfFile(file) {
        const self = RvmCliTools;
        let final_dir = self.normalizePath(path.dirname(file));
        fs.mkdirSync(final_dir, { recursive: true });
    }

    static readFile(path, encoding = 'utf8') {
        if(!encoding) {
            encoding = undefined;
        }
        return fs.readFileSync(path, encoding).toString();
    }

    static writeFile(path, content) {
        const self = RvmCliTools;
        self.makeDirOfFile(path);
        return fs.writeFileSync(path, content);
    }

    static copyFile(src, dest) {
        const self = RvmCliTools;
        self.makeDirOfFile(dest);
        fs.copyFileSync(src, dest);
    }

    static copy(src, dest) {
        const self = RvmCliTools;
        fse.copySync(src, dest);
    }

    static isDir(path) {
        const self = RvmCliTools;
        try {
            const stat = fs.lstatSync(path);
            return stat.isDirectory();
        } catch (e) {
            return false;
        }
    }

    static isFile(path) {
        const self = RvmCliTools;
        try {
            const stat = fs.lstatSync(path);
            return stat.isFile();
        } catch (e) {
            return false;
        }
    }

    static pathExists(path) {
        const self = RvmCliTools;
        try {
            const stat = fs.lstatSync(path);
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
        fs.rmSync(path, { recursive: true, force: true });
    }

    static escapeRegExp(string) {
        return string.replace(/[$+.*?^(){}|[\]\\]/g, '\\$&');
    }
}

RvmCliTools.GROBO_CONFIG_FILE_PATH = RvmCliTools.projectRootPath() + '/grobo.json';
RvmCliTools.PACKAGE_JSON_FILE_PATH = RvmCliTools.projectRootPath() + '/package.json';

RvmCliTools.GROBO_CONFIG_DEFAULTS = {
    shared_libs: {
        option_1: true,
        files: [
            { from: "assets/style", to: "" },
            { from: "assets/style", to: "" },
        ]
    }
}

RvmCliTools.first_question = true;
RvmCliTools.cached_config = null;

RvmCliTools.SECTIONS = {};
RvmCliTools.SECTIONS.not_inside_valid_project = [
    {
        header: 'Invalid project directory',
        content: [
            '{red You can run this command at the root directory of a project with grobo configuration only.}',
            '',
            `Current directory:\n {redBright ${RvmCliTools.projectRootPath()}}`
        ]
    }
];

if(RvmCliTools.isRunningInsideValidGroboProject()) {
    RvmCliTools.SECTIONS.invalid_config_paths = [
        {
            header: 'Invalid paths found',
            content: [
                'The following paths in grobo.json are invalid:',
                `   → ${RvmCliTools.invalidConfigPaths().map((el) => { return chalk.red(el); }).join("\n  → ")}`,
            ]
        }
    ];
}

module.exports = RvmCliTools;
