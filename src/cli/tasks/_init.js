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
        // add only if not already added to first position
        let exists_at_first_position = false;
        if (user_path && user_path.length > 0) {
            if(user_path.includes(";") && user_path.startsWith(rvm_wrapper_path + ";")) {
                exists_at_first_position = true;
            } else if(!user_path.includes(";") && user_path.startsWith(rvm_wrapper_path)) {
                exists_at_first_position = true;
            }
        }
        if (!exists_at_first_position) {
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
            let paths = [];
            try {
                paths = execSync(`chcp 65001 > NUL & where rvm`, {stdio: 'pipe'})
                    .toString()
                    .split(/\r?\n/)
                    .map(e => e.trim())
                    .filter(e => e);
            } catch (e) {
                // no global rvm shim available on PATH yet
            }

            // Bun's `bun link` can provide only an .exe shim. Look for editable wrappers or use .exe as base.
            let cmd_path_without_extension = null;

            const editable_wrapper = paths.find((p) => p.endsWith('.cmd') || p.endsWith('.ps1'));
            if (editable_wrapper) {
                const extension = editable_wrapper.split('.').getLast();
                cmd_path_without_extension = File.getBasename(editable_wrapper, extension).trim();
            } else if (paths.length > 0) {
                // No .cmd or .ps1 found, but we have paths (e.g., .exe from Bun link).
                // Use the .exe path as base to create/modify .cmd and .ps1 wrappers.
                let base_path = paths[0];
                if (base_path.endsWith('.exe')) {
                    cmd_path_without_extension = base_path.slice(0, -4); // Remove .exe extension
                } else {
                    cmd_path_without_extension = base_path;
                }
            }

            if (cmd_path_without_extension) {
                self._writeToSecondLine(cmd_path_without_extension, `echo "rvm-windows does only run on windows platforms!"; exit 1`);
                self._writeToSecondLine(cmd_path_without_extension + '.ps1', `& "${File.expandPath(RvmCliTools.rvmRootPath() + '/src/tools/current/ps_rvm_prepend.ps1')}"`);
                self._writeToSecondLine(cmd_path_without_extension + '.cmd', `call "${File.expandPath(RvmCliTools.rvmRootPath() + '/src/tools/current/cmd_rvm_prepend.bat')}"`);
            }
            FileUtils.mkdirP(RvmCliTools.rvmSessionsDir());
        }
        const session_id = RvmCliTools.getSessionId();
        // Only warn if no session mechanism is available at all.
        if(!session_id && process.argv[2] !== "init") {
            console.log(`${Chalk.red("No rvm session found!")} Run ${Chalk.green("rvm init")} to recreate session wrappers. Otherwise ${Chalk.green("rvm use")} is not working.`);
            console.log(``);
        }
        if(process.argv[2] === "init" && !process.env.RVM_SESSION && session_id) {
            console.log(`${Chalk.yellow("Info:")} RVM_SESSION env var may stay empty depending on runtime/link setup. rvm uses a process-based session id per terminal instead.`);
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
            const second_line = lines[1] ? lines[1].trim() : '';
            if (second_line !== line.trim()) {
                lines.splice(1, 0, line);
                File.write(file, lines.join('\n'));
            }
        }
        // If file doesn't exist, silently skip it. This handles Bun link scenarios where
        // wrapper files may not exist yet or are in different locations.
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
