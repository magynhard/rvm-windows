const RvmCliList = require('../../../src/cli/tasks/_list');
const RvmCliTools = require('../../../src/cli/_tools');
require('ruby-nice/object');

//----------------------------------------------------------------------------------------------------

const mockConfig = {
    "proxy": "",
    "default": "ruby-3.2.6",
    "last_run_boot_time": "2025-09-07T09:00:00.000Z",
    "rvm_data_dir": "C:\\ProgramData\\rvm",
    "envs": {
        "ruby-3.1.5": "C:/ProgramData/rvm/envs/ruby-3.1.5",
        "ruby-2.4.10": "C:/ProgramData/rvm/envs/ruby-2.4.10",
        "ruby-3.0.7": "C:/ProgramData/rvm/envs/ruby-3.0.7",
        "ruby-3.2.6": "C:/ProgramData/rvm/envs/ruby-3.2.6"
    }
};

let console_output = [];

//----------------------------------------------------------------------------------------------------

describe('RvmCliList', function () {
    describe('.runList()', function () {
        beforeEach(function () {
            // Override RvmCliTools.config() with a spy and return a mock config
            spyOn(RvmCliTools, 'config').and.returnValue(mockConfig);
            spyOn(console, 'log').and.callFake(msg => console_output.push(msg));
        });
        it('can list installed ruby versions', function () {
            // Check CLI output of the list command for installed versions
            RvmCliList.runList();
            expect(console_output[0].trim()).toContain('ruby-3.2.6');
            expect(console_output[1].trim()).toContain('ruby-3.1.5');
            expect(console_output[2].trim()).toContain('ruby-3.0.7');
            expect(console_output[3].trim()).toContain('ruby-2.4.10');
        });
    });
    describe('.runListAll()', function () {
        beforeEach(function () {
            // Override RvmCliTools.config() with a spy and return a mock config
            spyOn(RvmCliTools, 'config').and.returnValue(mockConfig);
        });
        it('can list all available ruby versions', async function () {
            // Check CLI output of the list command for installed versions
            const releases = await RvmCliList.runListAll();
            expect(releases.length).toBeGreaterThan(10);
            expect(releases).toContain('ruby-3.2.6');
            expect(releases).toContain('ruby-3.1.5');
            expect(releases).toContain('ruby-3.0.7');
            expect(releases).toContain('ruby-2.4.10');
        });
    });
    describe('.runListKnown()', function () {
        beforeEach(function () {
            // Override RvmCliTools.config() with a spy and return a mock config
            spyOn(RvmCliTools, 'config').and.returnValue(mockConfig);
        });
        it('can list known ruby versions', async function () {
            // Check CLI output of the list command for installed versions
            const releases = await RvmCliList.runListKnown();
            expect(releases.length).toBeGreaterThan(5);
            expect(releases.join()).toMatch('ruby-3.4');
            expect(releases.join()).toMatch('ruby-3.3');
            expect(releases.join()).toMatch('ruby-3.2');
            expect(releases.join()).toMatch('ruby-3.1');
            expect(releases.join()).toMatch('ruby-3.0');
            expect(releases.join()).toMatch('ruby-2.7');
            expect(releases.join()).toMatch('ruby-2.6');
            expect(releases.join()).toMatch('ruby-2.5');
            expect(releases.join()).toMatch('ruby-2.4');
        });
    });
    describe('.rubyInstallerReleasesList()', function () {
        beforeEach(function () {
        });
        it('can fetch ruby installer releases from GitHub', async function () {
            // Check CLI output of the list command for installed versions
            const releases = await RvmCliList.rubyInstallerReleasesList();
            expect(releases.length).toBeGreaterThan(10);
            const versions = releases.map(e => `ruby-${e.version}`);
            expect(versions).toContain('ruby-3.2.6');
            expect(versions).toContain('ruby-3.1.5');
            expect(versions).toContain('ruby-3.0.7');
            expect(versions).toContain('ruby-2.4.10');
        });
    });
});

//----------------------------------------------------------------------------------------------------