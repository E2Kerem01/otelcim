// Starts the Firestore + Storage emulators (via an already-installed
// firebase-tools, no network install) and runs every *.spec.ts under
// specs/ with node:test. Usage:
//   node run.mjs          -> normal run, known-bug tests are skipped
//   node run.mjs --bugs   -> un-skips the BUG-t2-* tests (they must FAIL,
//                            which proves each bug is real)
//   node run.mjs chat     -> only specs whose file name contains "chat"
//
// Overrides: FIREBASE_TOOLS_JS=<path to firebase-tools/lib/bin/firebase.js>,
//            T2_JAVA_HOME=<JDK >= 21 home>.
import { spawn, spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';

const here = dirname(fileURLToPath(import.meta.url));

function findFirebaseTools() {
  if (process.env.FIREBASE_TOOLS_JS) return process.env.FIREBASE_TOOLS_JS;
  const candidates = [];
  const npxCache = join(process.env.LOCALAPPDATA ?? join(homedir(), '.npm'), 'npm-cache', '_npx');
  for (const root of [npxCache, join(homedir(), '.npm', '_npx')]) {
    if (!existsSync(root)) continue;
    for (const hash of readdirSync(root)) {
      candidates.push(join(root, hash, 'node_modules', 'firebase-tools', 'lib', 'bin', 'firebase.js'));
    }
  }
  if (process.env.APPDATA) {
    candidates.push(join(process.env.APPDATA, 'npm', 'node_modules', 'firebase-tools', 'lib', 'bin', 'firebase.js'));
  }
  candidates.push(join(here, 'node_modules', 'firebase-tools', 'lib', 'bin', 'firebase.js'));
  const found = candidates.find((c) => existsSync(c));
  if (!found) throw new Error('firebase-tools not found; set FIREBASE_TOOLS_JS');
  return found;
}

function javaMajor(javaExe) {
  const r = spawnSync(javaExe, ['-version'], { encoding: 'utf8' });
  const m = /version "(\d+)/.exec(`${r.stderr}${r.stdout}`);
  return m ? Number(m[1]) : 0;
}

// firebase-tools >= 14 needs Java 21+ for the emulators.
function findJavaHome() {
  const exe = process.platform === 'win32' ? 'java.exe' : 'java';
  const homes = [process.env.T2_JAVA_HOME, process.env.JAVA_HOME].filter(Boolean);
  for (const root of ['C:/Program Files', join(homedir(), '.jdks'), '/usr/lib/jvm', '/Library/Java/JavaVirtualMachines']) {
    if (!existsSync(root)) continue;
    for (const vendor of readdirSync(root)) {
      const vendorDir = join(root, vendor);
      homes.push(vendorDir, join(vendorDir, 'Contents', 'Home'));
      try {
        for (const jdk of readdirSync(vendorDir)) homes.push(join(vendorDir, jdk));
      } catch {
        // not a directory
      }
    }
  }
  for (const home of homes) {
    const javaExe = join(home, 'bin', exe);
    if (existsSync(javaExe) && javaMajor(javaExe) >= 21) return home;
  }
  throw new Error('No JDK >= 21 found; set T2_JAVA_HOME');
}

// firebase-tools refuses rules files outside the directory holding
// firebase.json, so snapshot the repo's real rules into .rules/ (gitignored)
// on every run - the tests always exercise the current production rules.
const repoRoot = join(here, '..', '..', '..');
mkdirSync(join(here, '.rules'), { recursive: true });
for (const file of ['firestore.rules', 'storage.rules']) {
  copyFileSync(join(repoRoot, file), join(here, '.rules', file));
}

const only = process.argv.slice(2).filter((a) => !a.startsWith('--'));
const specs = readdirSync(join(here, 'specs'))
  .filter((f) => f.endsWith('.spec.ts'))
  .filter((f) => only.length === 0 || only.some((o) => f.includes(o)))
  .map((f) => `specs/${f}`);

const firebaseJs = findFirebaseTools();
const javaHome = findJavaHome();
const sep = process.platform === 'win32' ? ';' : ':';
const env = {
  ...process.env,
  JAVA_HOME: javaHome,
  PATH: `${join(javaHome, 'bin')}${sep}${process.env.PATH}`,
  T2_RUN_BUG_TESTS: process.argv.includes('--bugs') ? '1' : '',
  NO_UPDATE_NOTIFIER: '1',
};

const testCmd = `node --test --test-concurrency=1 ${specs.join(' ')}`;
console.log(`[t2] firebase-tools: ${firebaseJs}\n[t2] java: ${javaHome}\n[t2] ${testCmd}`);

const child = spawn(
  process.execPath,
  [firebaseJs, 'emulators:exec', '--only', 'firestore,storage', '--project', 'demo-otelcim', '--config', 'firebase.json', testCmd],
  { cwd: here, env, stdio: 'inherit' },
);
child.on('exit', (code) => process.exit(code ?? 1));
