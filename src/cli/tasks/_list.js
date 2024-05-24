#!/usr/bin/env node

const Chalk = require('chalk');
const {Octokit} = require('@octokit/rest');
const CommandLineUsage = require('command-line-usage');
const File = require('ruby-nice/file');

var RvmCliTools = require('./../_tools');
var RvmCliCurrent = require('./_current');
const {execSync} = require("child_process");

const octokit_rest = new Octokit({
    request: {
        fetch: RvmCliTools.fetchWithProxy
    }
});

class RvmCliList {
    static runList() {
        const self = RvmCliList;
        const config = RvmCliTools.config();
        config.envs.eachWithIndex((version, path) => {
            let prefix = "  ";
            if (version === RvmCliTools.getCurrentVersion()) {
                if (version === config.default) {
                    prefix = "=*";
                } else {
                    prefix = "=>";
                }
            } else if (version === config.default) {
                prefix = " *";
            }
            console.log(`${prefix} ${Chalk.green(version)}`);
        });
        self.legend();
    }

    static runListVerbose() {
        const self = RvmCliList;
        const config = RvmCliTools.config();
        let section = [{
            content: {
                options: {
                    noTrim: true
                },
                data: []
            },
        }];
        config.envs.eachWithIndex((version, path) => {
            let prefix = "  ";
            if (version === RvmCliTools.getCurrentVersion()) {
                if (version === config.default) {
                    prefix = "=*";
                } else {
                    prefix = "=>";
                }
            } else if (version === config.default) {
                prefix = " *";
            }
            section[0].content.data.push({
                prefix: prefix,
                version: Chalk.green(version),
                path: File.expandPath(path).replaceAll("\\","\\\\"),
                platform: execSync(`"${path}/bin/ruby.exe" --version`, {encoding: 'utf-8'}).toString().trim()
            });
        });
        console.log(CommandLineUsage(section));
        self.legend();
    }

    static runListKnown(silent = false) {
        const self = RvmCliList;
        return new Promise((resolve, reject) => {
            if (!silent) {
                console.log("\nRetrieving latest minor x64 devkit releases on\nhttps://rubyinstaller.org/downloads/archives/\n...");
            }
            const config = RvmCliTools.config();
            const installed_versions = Object.keys(config.envs);
            self.rubyInstallerReleasesList().then((releases) => {
                let beautified_releases = releases.map(e => e.version)
                    .sort(RvmCliTools.versionSort)
                    .reverse();
                let latest_minor_releases = [];
                // get all minor, e.g. 3.3, 3.2, 3.1, 2.7, 2.6
                const latest_minor_versions = [...new Set(beautified_releases.map(e => e.split(".").slice(0,2).join(".")))];
                latest_minor_versions.eachWithIndex((v, i) => {
                   const latest_patch = Math.max(...beautified_releases.filter(e => e.startsWith(v)).map(e => parseInt(e.split(".").getLast())));
                   latest_minor_releases.push(`${v}.${latest_patch}`);
                });
                const final_releases = latest_minor_releases.map((e) => {
                    return `ruby-${e}`;
                });
                if (!silent) {
                    console.log(
                        "\n - " + final_releases.map((version) => {
                            if (installed_versions.includes(version)) {
                                return Chalk.green(version);
                            } else {
                                return version;
                            }
                        }).join("\n - ")
                    );
                }
                resolve(final_releases);
            }).catch((e) => {
                reject(e);
            });
        });
    }

    static runListAll(silent = false) {
        const self = RvmCliList;
        return new Promise((resolve, reject) => {
            if (!silent) {
                console.log("\nRetrieving all x64 devkit releases on\nhttps://rubyinstaller.org/downloads/archives/\n...");
            }
            const config = RvmCliTools.config();
            const installed_versions = Object.keys(config.envs);
            self.rubyInstallerReleasesList().then((releases) => {
                const beautified_releases = releases.map(e => e.version)
                    .sort(RvmCliTools.versionSort)
                    .reverse()
                    .map((e) => {
                        return `ruby-${e}`;
                    });
                if (!silent) {
                    console.log(
                        "\n - " + beautified_releases.map((version) => {
                            if (installed_versions.includes(version)) {
                                return Chalk.green(version);
                            } else {
                                return version;
                            }
                        }).join("\n - ")
                    );
                }
                resolve(beautified_releases);
            }).catch((e) => {
                reject(e);
            });
        });
    }

    static runListUpgrades() {
        console.log(`Checking for available upgrades for installed ruby environments ...`);
        console.log();
        RvmCliList.runListKnown(true).then((list) => {
            RvmCliTools.config().envs.eachWithIndex((version, path) => {
                const minor_version = version.split(".").splice(0,2).join(".");
                let upgrade = RvmCliTools.matchingVersion(minor_version, list);
                if(upgrade === version) {
                    upgrade = `(up to date)`;
                    version = Chalk.green(version);
                } else {
                    version = Chalk.yellow(version);
                }
                if(upgrade.startsWith("ruby")) {
                    upgrade = Chalk.green(upgrade);
                }
                console.log(`${version} >> ${upgrade}`);
            });
        });
    }

    static githubReleasesList() {
        return new Promise((resolve, reject) => {
            octokit_rest.repos.listReleases({
                owner: 'oneclick',
                repo: 'rubyinstaller2'
            }).then((response) => {
                const releases = response.data.map(el => el.assets)
                    .flat()
                    .filter(el => el.browser_download_url.endsWith("x64.exe") && el.name.includes("devkit"))
                    .map(el => ({
                        download_url: el.browser_download_url,
                        label: el.name.replace("rubyinstaller-devkit-", "").replace("-x64.exe", "").substring(0, 5)
                    }))
                resolve(releases);
            }).catch((e) => {
                reject(e);
            });
        });
    }

    static rubyInstallerReleasesList() {
        const url = "https://rubyinstaller.org/downloads/archives/";
        return new Promise((resolve, reject) => {
            RvmCliTools.fetchWithProxy(url).then((response) => {
                response.text().then((html) => {
                    const releases_regex = /href="([^"]*devkit-([^"-]*)[-]?[0-9]+-x64.exe)"/gm;
                    const releases = html.scan(releases_regex).map((e) => {
                        return {
                            url: e[0],
                            version: e[1],
                        };
                    });
                    resolve(releases);
                });
            }).catch((e) => {
                console.error(Chalk.red(`Error retrieving releases from ${url}`));
                console.log();
                console.log(`Are you using a proxy? If yes, ensure you have configured a valid proxy with ${Chalk.green("rvm config")}. See more information by running ${Chalk.green("rvm help")}.`);
            });
        });
    }

    static legend() {
        const self = RvmCliList;
        console.log();
        console.log(`# => - current`);
        console.log(`# =* - current && default`);
        console.log(`#  * - default`);
    }
}

module.exports = RvmCliList;


