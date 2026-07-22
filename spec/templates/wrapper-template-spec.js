const Fs = require('fs');
const Os = require('os');
const Path = require('path');
const {spawnSync} = require('child_process');

describe('wrapper_template.bat', function () {
    let fixtureRoot;

    beforeEach(function () {
        fixtureRoot = Fs.mkdtempSync(Path.join(Os.tmpdir(), 'rvm-wrapper-'));
        const wrapperScriptsDir = Path.join(fixtureRoot, 'src', 'wrapper');
        Fs.mkdirSync(wrapperScriptsDir, {recursive: true});

        Fs.writeFileSync(
            Path.join(wrapperScriptsDir, 'wrapper_path.js'),
            "console.log('VER > NUL');\n"
        );
        Fs.writeFileSync(
            Path.join(wrapperScriptsDir, 'wrapper_rubypath.js'),
            "console.log('SET \"RUBYPATH=temporary-rubypath\"');\n"
        );
        Fs.writeFileSync(
            Path.join(wrapperScriptsDir, 'wrapper_proxy.js'),
            "console.log('');\n"
        );
        Fs.writeFileSync(
            Path.join(wrapperScriptsDir, 'wrapper_runner.js'),
            "console.log(`cmd.exe /d /c exit ${process.env.RVM_TEST_EXIT_CODE}`);\n"
        );
        Fs.writeFileSync(
            Path.join(wrapperScriptsDir, 'wrapper_after.js'),
            "console.log(`AFTER_COMMAND_RAN|RUBYPATH=${process.env.RUBYPATH}`);\n" +
            "process.exit(Number(process.env.RVM_TEST_AFTER_EXIT_CODE));\n"
        );

        const template = Fs.readFileSync(
            Path.join(__dirname, '..', '..', 'src', 'templates', 'wrapper_template.bat'),
            'utf8'
        );
        const renderedWrapper = template
            .replace('{{node_js_runtime_path}}', escapeBatchExecutablePath(process.execPath))
            .replace('{{rvm_root_dir}}', fixtureRoot);

        Fs.writeFileSync(Path.join(fixtureRoot, 'wrapper.bat'), renderedWrapper);
    });

    afterEach(function () {
        Fs.rmSync(fixtureRoot, {recursive: true, force: true});
    });

    function escapeBatchExecutablePath(filePath) {
        return filePath
            .split('\\')
            .map(segment => segment.includes(' ') ? `"${segment}"` : segment)
            .join('\\');
    }

    function runWrapper(exitCode, afterExitCode = 0) {
        return spawnSync('cmd.exe', ['/d', '/c', 'wrapper.bat'], {
            cwd: fixtureRoot,
            encoding: 'utf8',
            env: {
                ...process.env,
                RUBYPATH: 'original-rubypath',
                RVM_TEST_EXIT_CODE: String(exitCode),
                RVM_TEST_AFTER_EXIT_CODE: String(afterExitCode)
            }
        });
    }

    it('returns a failing wrapped command status after cleanup', function () {
        const result = runWrapper(42);

        expect(result.error).toBeUndefined();
        expect(result.stdout).toContain('AFTER_COMMAND_RAN|RUBYPATH=original-rubypath');
        expect(result.status).toBe(42);
    });

    it('returns zero when the wrapped command succeeds', function () {
        // The wrapped command succeeds with 0; a failing post-hook (17) must not replace that status.
        const result = runWrapper(0, 17);

        expect(result.error).toBeUndefined();
        expect(result.stdout).toContain('AFTER_COMMAND_RAN|RUBYPATH=original-rubypath');
        expect(result.status).toBe(0);
    });
});
