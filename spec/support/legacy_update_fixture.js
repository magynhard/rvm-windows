// Frozen finalisation behaviour of the previous updater, using only built-ins.
// Runs solely against the test's temporary npm prefix and harmless setup fixture.
const fs = require('fs');
const path = require('path');
const {execFileSync} = require('child_process');
const [prefix, archive, npmCli] = process.argv.slice(2);
const root = path.join(prefix, 'node_modules', 'rvm-windows');
const manifest = () => JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const previous = manifest().version;
execFileSync(process.execPath, [npmCli, 'install', '--global', '--prefix', prefix,
  '--foreground-scripts', '--allow-scripts=rvm-windows', '--no-audit', '--no-fund', archive], {stdio: 'inherit'});
if (manifest().version === previous) throw new Error('Expected a version update');
const helper = name => path.resolve(root, 'src', 'tools', 'current', name);
function secondLine(file, line) {
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  if ((lines[1] || '').trim() !== line.trim()) {
    lines.splice(1, 0, line);
    fs.writeFileSync(file, lines.join('\n'));
  }
}
// The old updater patches the npm launchers after npm has finished installing.
secondLine(path.join(prefix, 'rvm'), 'echo "rvm-windows does only run on windows platforms!"; exit 1');
secondLine(path.join(prefix, 'rvm.ps1'), `& "${helper('ps_rvm_prepend.ps1')}"`);
secondLine(path.join(prefix, 'rvm.cmd'), `call "${helper('cmd_rvm_prepend.bat')}"`);
console.log('Legacy update finalisation completed');
