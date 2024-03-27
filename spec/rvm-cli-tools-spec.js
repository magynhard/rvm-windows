const RvmCliVersion = require('../src/cli/tasks/_version');
require('ruby-nice/object');

//----------------------------------------------------------------------------------------------------

describe('RvmCliVersion', function () {
    beforeEach(function () {
    });
    it('can return a version', function () {
        expect(RvmCliVersion.getVersion()).toContain('.');
    });
});

//----------------------------------------------------------------------------------------------------
