#!/usr/bin/env node

const Chalk = require('chalk');
const {Octokit} = require('@octokit/rest');
const CommandLineUsage = require('command-line-usage');
const File = require('ruby-nice/file');
require('ruby-nice/string');
const Path = require('path');

var RvmCliTools = require('./../_tools');
const {execSync} = require("child_process");

const octokit_rest = new Octokit({
    request: {
        fetch: RvmCliTools.fetchWithProxy
    }
});

/**
 * Class for listing installed ruby versions and releases from rubyinstaller.org
 *
 * CLI:
 * - rvm list
 * - rvm list verbose
 * - rvm list known
 * - rvm list all
 * - rvm list upgrades
 */
class RvmCliList {
    /**
     * List all installed ruby versions.
     *
     * @example
     *
     * // CLI: rvm list
     *
     * RvmCliList.runList();
     *
     * // Output:
     * //
     * //   *   ruby-3.2.6
     * //       ruby-3.1.5
     * //  =>   ruby-3.0.7
     * //       ruby-2.4.10
     * //
     *
     */
    static runList() {
        const self = RvmCliList;
        const config = RvmCliTools.config();
        const sorted_versions = Object.keys(config.envs).sort(RvmCliTools.versionSort).reverse();
        sorted_versions.eachWithIndex((version) => {
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

    /**
     * List all installed ruby versions with additional information.
     *
     * @example
     *
     * // CLI: rvm list verbose
     *
     * RvmCliList.runListVerbose();
     *
     * // Output:
     * //
     * //       ruby-3.1.5    C:\ProgramData\rvm\envs\ruby-3.1.5    ruby 3.1.5p252 (2024-04-23 revision 1945f8dc0e) [x64-mingw-ucrt]
     * //       ruby-2.4.10   C:\ProgramData\rvm\envs\ruby-2.4.10   ruby 2.4.10p364 (2020-03-31 revision 67879) [x64-mingw32]
     * //  =>   ruby-3.0.7    C:\ProgramData\rvm\envs\ruby-3.0.7    ruby 3.0.7p220 (2024-04-23 revision 724a071175) [x64-mingw32]
     * //   *   ruby-3.2.6    C:\ProgramData\rvm\envs\ruby-3.2.6    ruby 3.2.6 (2024-10-30 revision 63aeb018eb) [x64-mingw-ucrt]
     * //
     *
     */
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
        const sorted_versions = Object.keys(config.envs).sort(RvmCliTools.versionSort).reverse();
        sorted_versions.eachWithIndex((version, i) => {
            const path = config.envs[version];
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
                path: File.expandPath(path).replaceAll("\\", "\\\\"),
                platform: execSync(`"${path}/bin/ruby.exe" --version`, {encoding: 'utf-8'}).toString().trim()
            });
        });
        console.log(CommandLineUsage(section));
        self.legend();
    }

    /**
     * List latest minor releases from rubyinstaller.org sorted by version descending.
     *
     * If MSYS2_PATH environment variable is set, only releases without devkit will be listed.
     *
     * @example
     *
     * // CLI: rvm list known
     *
     * RvmCliList.runListKnown();
     *
     * // Output:
     * //
     * // Retrieving latest minor x64 devkit releases on
     * // https://rubyinstaller.org/downloads/archives/
     * // ...
     * //
     * //  - ruby-3.4.5
     * //  - ruby-3.3.9
     * //  - ruby-3.2.9
     * //  - ruby-3.1.7
     * //  - ruby-3.0.7
     * //  - ruby-2.7.8
     * //  ...
     *
     * @param {boolean} silent
     * @returns {Promise<unknown>}
     */
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
                const latest_minor_versions = [...new Set(beautified_releases.map(e => e.split(".").slice(0, 2).join(".")))];
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

    /**
     * List all available releases from rubyinstaller.org sorted by version descending.
     *
     * If MSYS2_PATH environment variable is set, only releases without devkit will be listed.
     *
     * @example
     *
     * // CLI: rvm list all
     *
     * RvmCliList.runListAll();
     * // Output:
     * //
     * // Retrieving all x64 devkit releases on
     * // https://rubyinstaller.org/downloads/archives/
     * // ...
     * //
     * //  - ruby-3.4.5
     * //  - ruby-3.4.4
     * //  - ruby-3.4.4
     * //  - ruby-3.4.3
     * //  - ruby-3.4.2
     * //  ...
     *
     *
     * @param silent
     * @returns {Promise<unknown>}
     */
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

    /**
     * List available minor and patch upgrades for installed ruby versions.
     *
     * @example
     *
     * // CLI: rvm list upgrades
     *
     * RvmCliList.runListUpgrades();
     * // Output:
     * //
     * // Checking for available upgrades for installed ruby environments ...
     * //
     * // ruby-2.4.10 >> (up to date)
     * // ruby-3.0.7 >> (up to date)
     * // ruby-3.2.6 >> ruby-3.2.9
     */
    static runListUpgrades() {
        console.log(`Checking for available upgrades for installed ruby environments ...`);
        console.log();
        RvmCliList.runListKnown(true).then((list) => {
            RvmCliTools.config().envs.eachWithIndex((version, path) => {
                const minor_version = version.split(".").splice(0, 2).join(".");
                let upgrade = RvmCliTools.matchingVersion(minor_version, list);
                if (upgrade === version) {
                    upgrade = `(up to date)`;
                    version = Chalk.green(version);
                } else {
                    version = Chalk.yellow(version);
                }
                if (upgrade.startsWith("ruby")) {
                    upgrade = Chalk.green(upgrade);
                }
                console.log(`${version} >> ${upgrade}`);
            });
        });
    }

    /**
     * List available releases from GitHub api, by default with devkit.
     *
     * If MSYS2_PATH environment variable is set, only releases without devkit will be listed.
     *
     * @example
     *
     * RvmCliList.githubReleasesList().then((releases) => {
     *    console.log(releases);
     * });
     *
     *
     * // Output:
     * //
     * // [
     * //   {
     * //     download_url: 'https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.4.5-1/rubyinstaller-devkit-3.4.5-1-x64.exe',
     * //     label: '3.4.5'
     * //   },
     * //   {
     * //     download_url: 'https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.3.9-1/rubyinstaller-devkit-3.3.9-1-x64.exe',
     * //     label: '3.3.9'
     * //   },
     * //   {
     * //     download_url: 'https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.2.9-1/rubyinstaller-devkit-3.2.9-1-x64.exe',
     * //     label: '3.2.9'
     * //   },
     * //   {
     * //     download_url: 'https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.4.4-2/rubyinstaller-devkit-3.4.4-2-x64.exe',
     * //     label: '3.4.4'
     * //   }
     * // ]
     * @returns {Promise<unknown>}
     */
    static githubReleasesList() {
        return new Promise((resolve, reject) => {
            octokit_rest.repos.listReleases({
                owner: 'oneclick',
                repo: 'rubyinstaller2'
            }).then((response) => {
                let releases = response.data.map(el => el.assets).flat();
                if (self._hasValidMsys2Path()) {
                    releases = releases.filter(el => el.browser_download_url.endsWith("x64.exe") && !el.name.includes("devkit"));
                } else {
                    releases = releases.filter(el => el.browser_download_url.endsWith("x64.exe") && el.name.includes("devkit"));
                }
                releases = releases.map(el => ({
                    download_url: el.browser_download_url,
                    label: el.name.replace("rubyinstaller-devkit-", "").replace("rubyinstaller-", "").replace("-x64.exe", "").substring(0, 5)
                }));
                resolve(releases);
            }).catch((e) => {
                reject(e);
            });
        });
    }

    /**
     * Return all ruby installer releases from rubyinstaller.org, by default with devkit.
     *
     * If MSYS2_PATH environment variable is set, only releases without devkit will be listed.
     *
     * @example
     *
     * RvmCliList.rubyInstallerReleasesList().then((releases) => {
     *   console.log(releases);
     * });
     *
     * // Output:
     * //
     * // [
     * //   {
     * //     url: 'https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.4.5-1/rubyinstaller-devkit-3.4.5-1-x64.exe',
     * //     version: '3.4.5'
     * //   },
     * //   {
     * //     url: 'https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.3.9-1/rubyinstaller-devkit-3.3.9-1-x64.exe',
     * //     version: '3.3.9'
     * //   },
     * //   {
     * //     url: 'https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.2.9-1/rubyinstaller-devkit-3.2.9-1-x64.exe',
     * //     version: '3.2.9'
     * //   },
     * //   {
     * //     url: 'https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.4.4-2/rubyinstaller-devkit-3.4.4-2-x64.exe',
     * //     version: '3.4.4'
     * //   },
     * //   ...
     * // ]
     *
     * @returns {Promise<unknown>}
     */
    static rubyInstallerReleasesList() {
        const self = RvmCliList;
        const devkit_release_regex = /href="([^"]*[Dd]evkit-([^"-]*)[-]?[0-9]?-x64.exe)"/gm;
        const without_devkit_release_regex = /href="([^"]*[Rr]ubyinstaller-([^"-]*)[-]?[0-9]?-x64.exe)"/gm;
        const url = "https://rubyinstaller.org/downloads/archives/";
        return new Promise((resolve, reject) => {
            RvmCliTools.fetchWithProxy(url).then((response) => {
                response.text().then((html) => {
                    // Ensure ruby-nice/string is loaded for scan method
                    require('ruby-nice/string');
                    let releases_regex = null;
                    if (self._hasValidMsys2Path()) {
                        releases_regex = without_devkit_release_regex;
                    } else {
                        releases_regex = devkit_release_regex;
                    }
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

    /**
     * Legend for list output
     */
    static legend() {
        const self = RvmCliList;
        console.log();
        console.log(`# => - current`);
        console.log(`# =* - current && default`);
        console.log(`#  * - default`);
    }

    /**
     * Check if MSYS2_PATH environment variable is set and valid.
     *
     * Output a message if MSYS2_PATH is found and not silent.
     *
     * @param {Object} options
     * @returns {boolean} options.silent do not display a message on success
     * @private
     */
    static _hasValidMsys2Path(options = { silent: false }) {
        const self = RvmCliList;
        if(process.env["MSYS2_PATH"]) {
            if(File.isExisting(Path.join(process.env["MSYS2_PATH"], "usr/bin/msys-2.0.dll"))) {
                if(!options.silent) {
                    console.log(`\nMSYS2_PATH found: ${Chalk.green(process.env["MSYS2_PATH"])} ...\nFilter for ruby version(s) without devkit ...`);
                }
                return true;
            } else {
                if(!options.silent) {
                    console.log(Chalk.yellow(`MSYS2_PATH is set, but seems to be invalid: ${process.env["MSYS2_PATH"]} ... ignoring path ...`));
                }
                return false;
            }
        } else {
            return false;
        }
    }
}

module.exports = RvmCliList;
