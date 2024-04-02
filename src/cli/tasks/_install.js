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

const {fetch, ProxyAgent} = require("undici");


class RvmCliInstall {

    static install() {
        const self = RvmCliInstall;
        let version = process.argv[3];
        if (!version) {
            console.error(`No version given. Run ${Chalk.green('rvm install <version>')}, for example: ${Chalk.green('rvm install ruby-3.2.2')}`);
            process.exit(1);
        }
        // prefix ruby- if it starts with number
        if (RvmCliUse._startsWithNumber(version)) {
            version = "ruby-" + version;
        }
        RvmCliList.listKnown(true).then((releases) => {
            const version_match = RvmCliUse._matchingVersion(version, releases);
            if (version_match) {
                if (self.isAlreadyInstalled(version_match)) {
                    console.log(Chalk.yellow(`Already installed ${version_match}.`));
                    console.log(Chalk.yellow(`To reinstall use:`));
                    console.log(Chalk.yellow(`\n\trvm reinstall ${version_match}`));
                } else {
                    console.log(Chalk.green(`Installing ${version_match} ...`));
                    console.log();
                    RvmCliList.rubyInstallerReleasesList().then((list) => {
                        const final = list.find(e => `ruby-${e.version}` === version_match);
                        const file_name = final.url.split('/').slice(-1);
                        const destination = File.getHomePath() + '/.rvm/downloads/' + file_name;
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
        const install_dir = `${File.getHomePath()}/.rvm/envs/${version}`;
        FileUtils.mkdirP(install_dir);
        console.log(`Installing at ${Chalk.green(install_dir)} ... please wait, this task will take some minutes ...`);
        let proxy_command = '';
        const proxy = RvmCliTools.config().proxy;
        if(proxy) {
            proxy_command = `set HTTP_PROXY=${proxy} && set HTTPS_PROXY=${proxy} && `;
        }
        const command = `${proxy_command}"${source}" /verysilent /currentuser /dir="${install_dir}" /tasks="noassocfiles,nomodpath`;
        const result = execSync(command);
        let new_config = RvmCliTools.config();
        new_config.envs[version] = install_dir;
        RvmCliTools.writeRvmConfig(new_config);
        console.log(`Finished with status: ${result}`);
    }

    static isAlreadyInstalled(version) {
        const self = RvmCliInstall;
        return !!RvmCliUse._matchingVersion(version, RvmCliList.versions());
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

