#!/usr/bin/env node

const Chalk = require('chalk');
const {Octokit} = require('@octokit/rest');

var RvmCliTools = require('./../_tools');

const octokit_rest = new Octokit({
    request: {
        fetch: RvmCliTools.fetchWithProxy
    }
});

class RvmCliList {
    static list() {
        const self = RvmCliList;
        const config = RvmCliTools.config();
        config.envs.eachWithIndex((version, path) => {
            let prefix = "  ";
            if (version === config.current) {
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

    static listKnown(silent = false) {
        const self = RvmCliList;
        return new Promise((resolve, reject) => {
            if (!silent) {
                console.log("\nRetrieving x64 devkit releases on\nhttps://rubyinstaller.org/downloads/archives/\n...");
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
                console.error(`Error retrieving releases from ${url}`);
            });
        });
    }

    static versions() {
        const self = RvmCliList;
        return Object.keys(RvmCliTools.config().envs).sort(RvmCliTools.versionSort);
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


