const RvmCliConfig = require('../../../src/cli/tasks/_config');
const RvmCliTools = require('../../../src/cli/_tools');
require('ruby-nice/object');

//----------------------------------------------------------------------------------------------------

const mockConfig = {
    "proxy": {
        "enabled": false,
        "hostname": ""
    },
    "default": "ruby-3.2.6",
    "last_run_boot_time": "2025-09-07T09:00:00.000Z",
    "rvm_data_dir": "C:\\ProgramData\\test\\rvm",
    "envs": {
        "ruby-3.1.5": "C:/ProgramData/rvm/envs/ruby-3.1.5",
        "ruby-2.4.10": "C:/ProgramData/rvm/envs/ruby-2.4.10",
        "ruby-3.0.7": "C:/ProgramData/rvm/envs/ruby-3.0.7",
        "ruby-3.2.6": "C:/ProgramData/rvm/envs/ruby-3.2.6"
    }
};

let console_output = [];

//----------------------------------------------------------------------------------------------------

describe('RvmCliConfig', function () {
    describe('.printData()', function () {
        beforeEach(function () {
            // Override RvmCliTools.config() with a spy and return a mock config
            spyOn(RvmCliTools, 'config').and.returnValue(mockConfig);
            spyOn(console, 'log').and.callFake(msg => console_output.push(msg));
        });
        it('can print rvm data dir', function () {
            // Check CLI output
            RvmCliConfig.printData();
            expect(console_output[0].trim()).toContain("C:\\ProgramData\\test\\rvm");
        });
    });
});

//----------------------------------------------------------------------------------------------------