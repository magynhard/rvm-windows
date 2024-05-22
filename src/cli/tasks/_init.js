#!/usr/bin/env node

const Fs = require('fs');
const Os = require('os');
const Chalk = require('chalk');
const File = require('ruby-nice/file');
const FileUtils = require('ruby-nice/file-utils');
const Dir = require('ruby-nice/dir');
const {execSync} = require('child_process');

const child_process = require('child_process');


var RvmCliTools = require('./../_tools');
var RvmCliFix = require('./../tasks/_fix');
var RvmCliScan = require('./../tasks/_scan');

class RvmCliInit {
    /**
     * Ensure that the wrapper directory for ruby is set
     *
     * @param {boolean} silent do not display a message on success/error
     */
    static ensureWrapperPathEnvIsSet(silent = false) {
        const self = RvmCliInit;
        const rvm_wrapper_path = File.expandPath(`${RvmCliTools.getRvmDataDir()}/wrapper`);
        let user_path = self.getUserPath();
        // add only if not already added
        if (user_path && !user_path.startsWith(rvm_wrapper_path)) {
            user_path = user_path.replace(";" + rvm_wrapper_path, ""); // remove existing path
            // add at the beginning of path env variable
            const add_path_cmd = `chcp 65001 > NUL && setx PATH "${rvm_wrapper_path};${user_path}"`;
            let stdout3 = null;
            try {
                execSync(add_path_cmd, {encoding: 'utf-8', stdio: 'ignore'});
                if (!silent) {
                    console.log(`Added path successfully!`);
                }
            } catch (e) {
                if (!silent) {
                    console.error(`Error when adding path: ${e.message}`);
                }
            }
        } else {
            if (!silent) {
                console.warn(`Path is already added!`);
            }
        }
    }

    static reloadCmd(path) {
        child_process.spawn(
            // With this variable we know we use the same shell as the one that started this process
            "C:\\Windows\\System32\\cmd.exe",
            {
                stdio: 'inherit',
                // set path environment variable
                env: {...process.env, PATH: path},
            },
        );
    }

    static getUserPath() {
        const get_user_path_batch = RvmCliTools.rvmRootPath() + '/src/tools/path/get_user_path.bat';
        return execSync(get_user_path_batch, {encoding: 'utf-8'});
    }

    static initSessionToRvmExes(force = false) {
        const self = RvmCliInit;
        if (!Dir.isExisting(RvmCliTools.rvmSessionsDir()) || force) {
            let paths = execSync(`chcp 65001 > NUL & where rvm`, {stdio: 'pipe'}).toString();
            paths = paths.split("\n");
            const cmd_path = paths[0];
            let cmd_path_without_extension = null;
            if (cmd_path && cmd_path.endsWith(".cmd") || cmd_path.endsWith(".ps1")) {
                cmd_path_without_extension = File.getBasename(cmd_path, cmd_path.split(".").getLast());
            } else {
                cmd_path_without_extension = cmd_path;
            }
            cmd_path_without_extension = cmd_path_without_extension.trim();
            self._writeToSecondLine(cmd_path_without_extension, `echo "rvm-windows does only run on windows platforms!"; exit 1`);
            self._writeToSecondLine(cmd_path_without_extension + '.ps1', `& "${File.expandPath(RvmCliTools.rvmRootPath() + '/src/tools/current/ps_rvm_prepend.ps1')}"`);
            self._writeToSecondLine(cmd_path_without_extension + '.cmd', `call "${File.expandPath(RvmCliTools.rvmRootPath() + '/src/tools/current/cmd_rvm_prepend.bat')}"`);
            FileUtils.mkdirP(RvmCliTools.rvmSessionsDir());
        }
        if(!process.env.RVM_SESSION && process.argv[2] !== "init") {
            console.log(`${Chalk.red("No rvm session found!")} Run ${Chalk.green("rvm init")} to recreate session wrappers. Otherwise ${Chalk.green("rvm use")} is not working.`);
            console.log(``);
        }
        self._cleanSessions();
    }

    /**
     * Clean sessions if system has been booted since last run
     *
     * @private
     */
    static _cleanSessions() {
        const current_time = Date.now();
        const uptime_in_seconds = Os.uptime();
        const current_boot_time = new Date(current_time - uptime_in_seconds * 1000);
        if (!RvmCliTools.config().last_run_boot_time) {
            let config = RvmCliTools.config();
            config.last_run_boot_time = current_boot_time;
            RvmCliTools.writeRvmConfig(config);
        } else {
            let last_boot_time = new Date(RvmCliTools.config().last_run_boot_time);
            // as the seconds and milliseconds differ because execution time of script is included, we remove them for comparison
            last_boot_time.setSeconds(0);
            last_boot_time.setMilliseconds(0);
            current_boot_time.setSeconds(0);
            current_boot_time.setMilliseconds(0);
            if(last_boot_time.getTime() !== current_boot_time.getTime()) {
                FileUtils.rmRf(RvmCliTools.rvmSessionsDir());
                FileUtils.mkdirP(RvmCliTools.rvmSessionsDir());
                let config = RvmCliTools.config();
                config.last_run_boot_time = current_boot_time;
                RvmCliTools.writeRvmConfig(config);
            }
        }
    }

    static _writeToSecondLine(file, line) {
        if (File.isExisting(file)) {
            const content = File.read(file);
            const lines = content.split('\n');
            if (lines[1].trim() !== line.trim()) {
                lines.splice(1, 0, line);
                File.write(file, lines.join('\n'));
            }
        } else {
            throw new Error(`Could not find file '${file}'`);
        }
    }

    static initAfterInstall(force = false) {
        const self = RvmCliInit;
        if (!File.isExisting(RvmCliTools.rvmConfigPath()) || force) {
            RvmCliFix.fixConfig();
            self.ensureWrapperPathEnvIsSet(true);
            RvmCliScan.runScan();
            console.log(`RVM has been initialized and is ready to use! (Open terminals will need to be restarted to reload PATH environment variable)`);
        }
    }

    static ensureWrapperIsFirstInPath() {
        let paths = [];
        try {
            const raw_paths = execSync(`chcp 65001 > NUL & where ruby`, { stdio: 'pipe'}).toString();
            paths = raw_paths.split("\n").map(e => e.trim());
        } catch (e) {
            // no installed ruby in PATH available
        }
        if(paths.length > 0 && !File.expandPath(paths[0]).includes("\\rvm\\wrapper")) {
            console.warn(`${Chalk.yellow("Warning: rvm-windows wrapper ruby is not the first ruby in path! Other ruby is configured before!")}`);
            console.log(`To fix this, try ${Chalk.green("rvm init")} and restart your terminal!`);
            console.log(`If this does not work, your system PATH may include rubies, that needs to be removed manually!`);
            console.log();
            console.log(`${Chalk.yellow("Ruby paths in following order found:")}`);
            console.log(paths.filter(a => a).map(e => `- ${e}`).join("\n"));
            console.log();
        }
    }
}

module.exports = RvmCliInit;


