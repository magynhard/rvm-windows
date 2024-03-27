#!/usr/bin/env node

const Fs = require('fs');
const File = require('ruby-nice/file');
const {execSync} = require('child_process');
const Chalk = require('chalk');
const Axios = require('axios');
const HttpsProxyAgent = require('hpagent');
const { Octokit } = require('@octokit/rest');
const fetch2 = require('node-fetch');
const { ProxyAgent, fetch } = require("undici");

const myFetch = (url, opts) => {
    return fetch(url, {
        ...opts,
        dispatcher: new ProxyAgent({
            uri: process.env.HTTPS_PROXY || 'http://127.0.0.1:3128',
            keepAliveTimeout: 10,
            keepAliveMaxTimeout: 10,
        }),
    });
};

const octokit_rest = new Octokit({
    request: {
        fetch: myFetch
    }
});

var RvmCliTools = require('./../_tools');

class RvmCliList {
    static list() {
        const self = RvmCliList;
        const config = RvmCliTools.config();
        config.envs.eachWithIndex((version, path) => {
            let prefix = "  ";
            if (version === config.current) {
                if(version === config.default) {
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

    static listKnown() {
        const self = RvmCliList;
        console.log("\nRetrieving x64 devkit releases on\nhttps://github.com/oneclick/rubyinstaller2/releases\n...");
        const config = RvmCliTools.config();
        const installed_versions = Object.keys(config.envs);
        self.githubReleasesList().then((releases) => {
           console.log(
               "\n - " + releases.map(e => e.label)
                   .sort()
                   .reverse()
                   .map((e) => {
                       let version = `ruby-${e}`;
                       if(installed_versions.includes(version)) {
                           version = Chalk.green(version);
                       }
                       return version;
                   }).join("\n - ")
           );
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
                    .map(el => ({ download_url: el.browser_download_url, label: el.name.replace("rubyinstaller-devkit-","").replace("-x64.exe","").substring(0,5)}))
                resolve(releases);
            }).catch((e) => {
                reject(e);
            });
        });
    }

    static versions() {
        const self = RvmCliList;
        return Object.keys(RvmCliTools.config().envs);
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


