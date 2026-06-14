const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');

// 1. Read current version
const packageJson = JSON.parse(fs.readFileSync(path.join(rootDir, 'package.json'), 'utf8'));
const currentVersion = packageJson.version;
const [major, minor, patch] = currentVersion.split('.').map(Number);
const newVersion = `${major}.${minor}.${patch + 1}`;
const newVersionTag = `v${newVersion}`;

// 2. Get today's date in YYYY-MM-DD format
const today = new Date().toISOString().split('T')[0];

// 3. Check CHANGELOG.md
const changelogPath = path.join(rootDir, 'CHANGELOG.md');
let changelog;
try {
  changelog = fs.readFileSync(changelogPath, 'utf8');
} catch (e) {
  console.error(`\nError: CHANGELOG.md not found at ${changelogPath}`);
  console.error(`Please create it with an entry for version ${newVersion}.\n`);
  process.exit(1);
}

const expectedPattern = new RegExp(`#\\s*${newVersion.replace(/\./g, '\\.')}\\s*-\\s*${today}`);
if (!expectedPattern.test(changelog)) {
  console.error(`\nError: CHANGELOG.md is missing an entry for version ${newVersion} with today's date (${today}).`);
  console.error(`\nPlease add an entry at the top of CHANGELOG.md:\n`);
  console.error(`  # ${newVersion} - ${today}`);
  console.error(`  - Your changes here\n`);
  process.exit(1);
}

console.log(`CHANGELOG.md validated: entry for ${newVersion} - ${today} found.`);

// 4. Run tests
console.log(`\nRunning tests...`);
try {
  execSync('npm test', { cwd: rootDir, stdio: 'inherit' });
} catch (e) {
  console.error(`\nError: Tests failed. Aborting release.\n`);
  process.exit(1);
}

// 5. Bump version (creates commit and tag)
console.log(`\nBumping version to ${newVersion}...`);
try {
  execSync('npm version patch --git-tag-version', { cwd: rootDir, stdio: 'inherit' });
} catch (e) {
  console.error(`\nError: Version bump failed. Aborting release.\n`);
  process.exit(1);
}

// 6. Push to origin
console.log(`\nPushing to origin...`);
try {
  execSync('git push origin master --tags', { cwd: rootDir, stdio: 'inherit' });
} catch (e) {
  console.error(`\nError: Git push failed. Version was bumped locally but not pushed.\n`);
  process.exit(1);
}

// 7. Publish to npm
console.log(`\nPublishing to npm...`);
try {
  execSync('npm publish --access public', { cwd: rootDir, stdio: 'inherit' });
} catch (e) {
  console.error(`\nError: npm publish failed. Version was pushed to git but not published to npm.\n`);
  process.exit(1);
}

console.log(`\nRelease ${newVersionTag} complete!`);
