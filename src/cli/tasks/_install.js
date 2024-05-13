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
var RvmCliList = require('./../tasks/_list');
var RvmCliFix = require('./_fix');


class RvmCliInstall {

    static runInstall(version) {
        const self = RvmCliInstall;
        version = version || process.argv[3];
        if (!version) {
            console.error(`No version given. Run ${Chalk.green('rvm install <version>')}, for example: ${Chalk.green('rvm install ruby-3.2.2')}`);
            process.exit(1);
        }
        // prefix ruby- if it starts with number
        if (RvmCliTools.startsWithNumber(version)) {
            version = "ruby-" + version;
        }
        RvmCliList.runListKnown(true).then((releases) => {
            const version_match = RvmCliTools.matchingVersion(version, releases);
            if (version_match) {
                if (self.isAlreadyInstalled(version_match)) {
                    console.log(Chalk.yellow(`Already installed ${version_match}.`));
                    console.log(`To reinstall use:`);
                    console.log(Chalk.green(`\n\trvm reinstall ${version_match}`));
                } else {
                    console.log(Chalk.green(`Installing ${version_match} ...`));
                    console.log();
                    RvmCliList.rubyInstallerReleasesList().then((list) => {
                        const final = list.find(e => `ruby-${e.version}` === version_match);
                        const file_name = final.url.split('/').slice(-1);
                        const destination = RvmCliTools.getRvmDataDir() + '/downloads/' + file_name;
                        if(File.isExisting(destination)) {
                            console.log(`Found and use cached ${Chalk.green(destination)}`);
                            self.runInstaller(destination, version_match);
                        } else {
                            console.log(`Downloading ${Chalk.green(final.url)} ... please wait ...`);
                            self.download(final.url, destination).then(() => {
                                console.log("Download successful!");
                                self.runInstaller(destination, version_match);
                            }).catch((e) => {
                                console.error("Error downloading file!", e.message);
                            });
                            console.log("");
                        }
                    });
                }
            } else {
                console.log(Chalk.red(`Version ${version} is not available.`));
                console.log(Chalk.red(`To list available versions use:`));
                console.log(Chalk.red(`\n\trvm list known`));
            }
        });
    }

    static runInstaller(source, version) {
        const install_dir = File.expandPath(`${RvmCliTools.getRvmDataDir()}/envs/${version}`);
        FileUtils.mkdirP(install_dir);
        console.log(`Installing at ${Chalk.green(install_dir)} ... please wait, this task will take some minutes ...`);
        let proxy_command = '';
        const proxy = RvmCliTools.config().proxy;
        if(proxy) {
            proxy_command = `set HTTP_PROXY=${proxy} && set HTTPS_PROXY=${proxy} && `;
        }
        const command = `${proxy_command}"${source}" /verysilent /currentuser /dir="${install_dir}" /tasks="noassocfiles,nomodpath`;
        const result = execSync(command, {encoding: 'utf-8'});
        let new_config = RvmCliTools.config();
        new_config.envs[version] = install_dir;
        if(!new_config.default) {
            new_config.default = version;
        }
        RvmCliTools.writeRvmConfig(new_config);
        RvmCliTools.setCurrentVersion(version);
        RvmCliFix.fixWrapperFiles();
        console.log(`Installation complete!\n\nRun ${Chalk.green("rvm kit")} to install development tools and a bunch of widely used x64 dependencies automatically.`);
    }

    static isAlreadyInstalled(version) {
        const self = RvmCliInstall;
        return !!RvmCliTools.matchingVersion(version, RvmCliTools.versions());
    }

    static download(url, destination) {
        const self = RvmCliInstall;
        return self.downloadPromise(url, destination);
    }

    static async downloadPromise(url, destination) {
        const file_name = url.split('/').slice(-1);
        FileUtils.mkdirP(File.getDirname(destination));
        const res = await RvmCliTools.fetchWithProxy(url);
        const fileStream = fs.createWriteStream(destination, {flags: 'wx'});
        await finished(Readable.fromWeb(res.body).pipe(fileStream));
    }
}

module.exports = RvmCliInstall;


