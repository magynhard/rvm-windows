#!/usr/bin/env node

const fs = require('fs');
const https = require('https');
const File = require('ruby-nice/file');
const FileUtils = require('ruby-nice/file-utils');
const Path = require("path");
const {execSync} = require('child_process');
const {finished} = require('stream/promises');
const {Readable} = require('stream');
const Chalk = require('chalk');

var RvmCliTools = require('./../_tools');
var RvmCliUse = require('./../tasks/_use');
var RvmCliConfig = require('./../tasks/_config');
var RvmCliList = require('./../tasks/_list');
var RvmCliFix = require('./_fix');


class RvmCliInstall {

    /**
     * Install a ruby version into the given directory.
     * If no directory is given, the default directory will be used.
     *
     * @example
     *
     * RvmCliInstall.runInstall("ruby-3.2.2", "C:/Ruby-3.2.2x64");
     * RvmCliInstall.runInstall("3.2.2"); // will be installed into default directory
     * RvmCliInstall.runInstall(); // will use process.argv[3] as version if run from command line
     *
     * @param {string} version
     * @param {string} install_dir
     */
    static runInstall(version, install_dir) {
        const self = RvmCliInstall;
        version = version || process.argv[3];
        if (!version) {
            console.error(`${Chalk.red("No version given.")} Run ${Chalk.green('rvm install <version>')}, for example: ${Chalk.green('rvm install ruby-3.2.2')}`);
            process.exit(1);
        }
        // prefix ruby- if it starts with number
        if (RvmCliTools.startsWithNumber(version)) {
            version = "ruby-" + version;
        }
        RvmCliList.runListAll(true).then((releases) => {
            const version_match = RvmCliTools.matchingVersion(version, releases);
            if (version_match) {
                if (self.isAlreadyInstalled(version_match)) {
                    console.log(Chalk.yellow(`Already installed ${version_match}.`));
                    console.log(`To reinstall use:`);
                    console.log(Chalk.green(`\n\trvm reinstall ${version_match}`));
                } else {
                    console.log(`Installing ${Chalk.green(version_match)} ...`);
                    console.log();
                    RvmCliList.rubyInstallerReleasesList().then((list) => {
                        const final = list.find(e => `ruby-${e.version}` === version_match);
                        const file_name = final.url.split('/').slice(-1);
                        const destination = File.expandPath(RvmCliTools.getRvmDataDir() + '/downloads/' + file_name);
                        if(File.isExisting(destination)) {
                            console.log(`Found and use cached ${Chalk.green(destination)}`);
                            self.runInstaller(destination, version_match, install_dir);
                        } else {
                            console.log(`Downloading ${Chalk.green(final.url)} ... please wait ...`);
                            self.download(final.url, destination).then(() => {
                                console.log("Download successful!");
                                self.runInstaller(destination, version_match, install_dir);
                            }).catch((e) => {
                                console.error("Error downloading file!", e.message);
                            });
                            console.log("");
                        }
                    });
                }
            } else {
                console.log(Chalk.red(`Version ${version} is not available.`));
                console.log(`To list available versions use:`);
                console.log(Chalk.green(`\n\trvm list known`));
            }
        });
    }

    /**
     * Run the installer with silent mode and add the new installation to the rvm config.
     *
     * @example
     *
     * RvmCliInstall.runInstaller("C:/path/to/installer.exe", "ruby-3.2.2", "C:/Ruby-3.2.2x64");
     * RvmCliInstall.runInstaller("C:/path/to/installer.exe", "ruby-3.2.2"); // will be installed into default directory
     *
     * @param {string} source installer file path
     * @param {string} version ruby version (e.g. ruby-3.2.2)
     * @param {string} install_dir overwrite automatic directory detection
     */
    static runInstaller(source, version, install_dir) {
        const self = RvmCliInstall;
        install_dir = install_dir || File.expandPath(`${RvmCliTools.getRvmDataDir()}/envs/${version}`);
        FileUtils.mkdirP(install_dir);
        console.log(`Installing at ${Chalk.green(File.expandPath(install_dir))} ... please wait, this task will take some minutes ...`);
        // Remove RubyInstaller's InnoSetup uninstall registry key for the same minor version
        // to prevent the installer from silently uninstalling a previously installed patch version.
        // RubyInstaller uses an AppId based on major.minor (e.g. "RubyInstaller-3.3-x64"),
        // so installing 3.3.9 would otherwise auto-uninstall an existing 3.3.8.
        self.removeRubyInstallerRegistryKey(version);
        let proxy_command = '';
        const proxy = RvmCliTools.config().proxy;
        if(proxy?.enabled && proxy?.hostname) {
            proxy_command = `set HTTP_PROXY=${proxy.hostname} && set HTTPS_PROXY=${proxy.hostname} && `;
        }
        const command = `${proxy_command}"${source}" /verysilent /currentuser /dir="${install_dir}" /tasks="noassocfiles,nomodpath"`;
        const result = execSync(command, {encoding: 'utf-8'});
        let new_config = RvmCliTools.config();
        // remove existing installation with same dir (if upgrade)
        new_config.envs.eachWithIndex((v, p, i) => {
           if(p === install_dir) {
               delete new_config.envs[v];
           }
        });
        new_config.envs[version] = install_dir;
        if(!new_config.default) {
            new_config.default = version;
        }
        if(!new_config.default) {
            new_config.default = version;
        }
        RvmCliTools.writeRvmConfig(new_config);
        RvmCliFix.fixWrapperFiles();
        console.log(`Installation complete!\n`);
        RvmCliUse.runUse(version);
        const default_exists = !!(RvmCliTools.config().envs[RvmCliTools.config().default]);
        if(!default_exists) {
            RvmCliConfig.runDefault(version);
        }
        RvmCliTools.killRunningMsysProcesses();
        console.log(`\nRun ${Chalk.green("rvm kit")} to install development tools and a bunch of widely used x64 dependencies automatically.`);
    }

    /**
     * Remove the RubyInstaller InnoSetup uninstall registry key for the given version's minor version.
     *
     * RubyInstaller uses an AppId based on major.minor and platform
     * (e.g. "RubyInstaller-3.3-x64-mingw-ucrt" or "RubyInstaller-3.1-x64-mingw32"),
     * which means its built-in upgrade logic will silently uninstall any existing installation
     * of the same minor version before installing the new one.
     *
     * By removing the registry key before running the installer, we prevent this auto-uninstall
     * and allow multiple patch versions of the same minor to coexist side by side.
     *
     * @example
     *
     * RvmCliInstall.removeRubyInstallerRegistryKey("ruby-3.3.9");
     * // removes HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\RubyInstaller-3.3-x64-mingw-ucrt_is1
     *
     * @param {string} version ruby version (e.g. ruby-3.3.9)
     */
    static removeRubyInstallerRegistryKey(version) {
        const minor_version = version.replace("ruby-", "").split(".").slice(0, 2).join(".");
        const uninstall_path = `HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall`;
        try {
            const output = execSync(`reg query "${uninstall_path}" /f "RubyInstaller-${minor_version}" /k`, {encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore']});
            const lines = output.split(/\r?\n/).filter(l => l.includes(`RubyInstaller-${minor_version}`));
            lines.forEach((line) => {
                const reg_key = line.trim();
                if (reg_key) {
                    try {
                        execSync(`reg delete "${reg_key}" /f`, {stdio: 'ignore'});
                    } catch (e) {
                        // key could not be deleted, ignore
                    }
                }
            });
        } catch (e) {
            // no matching registry keys found, nothing to do
        }
    }

    /**
     * Check if the given version is already installed.
     *
     * @example
     *
     * RvmCliInstall.isAlreadyInstalled("ruby-3.2.2"); // true/false
     * RvmCliInstall.isAlreadyInstalled("3"); // true/false
     *
     * @param {string} version
     * @returns {boolean}
     */
    static isAlreadyInstalled(version) {
        const self = RvmCliInstall;
        return !!RvmCliTools.matchingVersion(version, RvmCliTools.versions());
    }

    /**
     * Download a file from the given url to the given destination.
     * If the destination directory does not exist, it will be created.
     * The file will not be downloaded again if it already exists.
     * If the download fails, an error will be thrown.
     *
     * @param {string} url
     * @param {string} destination
     * @returns {Promise<void>}
     */
    static download(url, destination) {
        const self = RvmCliInstall;
        return self.downloadPromise(url, destination);
    }

    /**
     * Download a file from the given url to the given destination.
     *
     * @param url
     * @param destination
     * @returns {Promise<void>}
     */
    static async downloadPromise(url, destination) {
        const file_name = url.split('/').slice(-1);
        FileUtils.mkdirP(File.getDirname(destination));
        const res = await RvmCliTools.fetchWithProxy(url);
        const fileStream = fs.createWriteStream(destination, {flags: 'wx'});
        await finished(Readable.fromWeb(res.body).pipe(fileStream));
    }
}

module.exports = RvmCliInstall;


