const Fs = require('fs');
const Os = require('os');
const Path = require('path');
const {execSync} = require('child_process');
const RvmCliInit = require('../../../src/cli/tasks/_init');
const RvmCliTools = require('../../../src/cli/_tools');

describe('RvmCliInit.getUserPath()', function () {
    it('reads the user PATH when the installation path contains spaces', function () {
        if (process.platform !== 'win32') {
            pending('Batch files require Windows');
        }

        const temporary_dir = Fs.mkdtempSync(Path.join(Os.tmpdir(), 'rvm-init-'));
        try {
            const source = Path.resolve(__dirname, '../../../src/tools/path/get_user_path.bat');
            const expected = execSync(`"${source}"`, {encoding: 'utf-8'});
            const root = spyOn(RvmCliTools, 'rvmRootPath');

            for (const name of ['NoSpaces', 'Author Software']) {
                const directory = Path.join(temporary_dir, name);
                const batch = Path.join(directory, 'src/tools/path/get_user_path.bat');
                Fs.mkdirSync(Path.dirname(batch), {recursive: true});
                Fs.copyFileSync(source, batch);
                root.and.returnValue(directory);
                expect(RvmCliInit.getUserPath()).toBe(expected);
            }
        } finally {
            Fs.rmSync(temporary_dir, {recursive: true, force: true});
        }
    });
});
