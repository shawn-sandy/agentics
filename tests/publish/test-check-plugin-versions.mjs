import {
  findViolations,
  isHigher,
  manifestChangedPlugins,
  parseSemver,
} from '../../scripts/check-plugin-versions.mjs';

let pass = 0;
let fail = 0;

function check(name, cond) {
  if (cond) {
    console.log(`PASS: ${name}`);
    pass++;
  } else {
    console.log(`FAIL: ${name}`);
    fail++;
  }
}

// ── semver ─────────────────────────────────────────────────────────────────

check('parses x.y.z', JSON.stringify(parseSemver('1.2.3')) === '[1,2,3]');
check('rejects non-semver', parseSemver('1.2') === null && parseSemver('v1.2.3') === null);
check('patch bump is higher', isHigher('1.0.1', '1.0.0'));
check('minor bump is higher', isHigher('1.1.0', '1.0.9'));
check('major bump is higher', isHigher('2.0.0', '1.9.9'));
check('equal is not higher', !isHigher('1.0.0', '1.0.0'));
check('downgrade is not higher', !isHigher('1.0.0', '1.0.1'));
check('10 > 9 numerically, not lexically', isHigher('1.10.0', '1.9.0'));

// ── violations ─────────────────────────────────────────────────────────────

const base = { plugins: [{ name: 'alpha', version: '1.0.0' }, { name: 'beta', version: '2.3.4' }] };

const changed = ['kit/plugins/alpha/skills/foo/SKILL.md'];

check(
  'changed plugin without bump is a violation',
  findViolations(changed, base, base).length === 1,
);

check(
  'changed plugin with bump passes',
  findViolations(changed, { plugins: [{ name: 'alpha', version: '1.0.1' }, ...base.plugins.slice(1)] }, base).length === 0,
);

check(
  'untouched plugin is ignored',
  findViolations(['README.md', 'docs/plans/x.html'], base, base).length === 0,
);

check(
  'downgrade is a violation',
  findViolations(changed, { plugins: [{ name: 'alpha', version: '0.9.0' }] }, base).length === 1,
);

check(
  'new plugin needs no bump',
  findViolations(['kit/plugins/gamma/skills/g/SKILL.md'], { plugins: [...base.plugins, { name: 'gamma', version: '0.1.0' }] }, base).length === 0,
);

check(
  'plugin absent from manifest is ignored (does not ship)',
  findViolations(['kit/plugins/ghost/skills/g/SKILL.md'], base, base).length === 0,
);

check(
  'unparseable version is a violation',
  findViolations(changed, { plugins: [{ name: 'alpha', version: 'latest' }] }, base)[0]?.reason === 'unparseable version',
);

check(
  'two changed plugins report two violations',
  findViolations(['kit/plugins/alpha/a.md', 'kit/plugins/beta/b.md'], base, base).length === 2,
);

// ── manifest-only changes ──────────────────────────────────────────────────
// A plugin's marketplace entry can change with no file under kit/plugins/
// touched. marketplace.md calls metadata corrections PATCH bumps.

const withMeta = {
  plugins: [
    { name: 'alpha', version: '1.0.0', description: 'old', tags: ['a', 'b'] },
    { name: 'beta', version: '2.3.4' },
  ],
};
const editDesc = (version, description) => ({
  plugins: [
    { name: 'alpha', version, description, tags: ['a', 'b'] },
    { name: 'beta', version: '2.3.4' },
  ],
});

check(
  'description edit alone marks the plugin changed',
  manifestChangedPlugins(editDesc('1.0.0', 'new'), withMeta).has('alpha'),
);

check(
  'a version-only diff is the bump, not a change demanding one',
  !manifestChangedPlugins(editDesc('1.0.1', 'old'), withMeta).has('alpha'),
);

check(
  'identical manifests mark nothing changed',
  manifestChangedPlugins(withMeta, withMeta).size === 0,
);

check(
  'manifest-only description edit without bump is a violation',
  findViolations([], editDesc('1.0.0', 'new'), withMeta).length === 1,
);

check(
  'manifest-only description edit with bump passes',
  findViolations([], editDesc('1.0.1', 'new'), withMeta).length === 0,
);

check(
  'tags edit without bump is a violation',
  findViolations([], { plugins: [{ name: 'alpha', version: '1.0.0', description: 'old', tags: ['a'] }] }, withMeta).length === 1,
);

check(
  'key reordering is not a change',
  manifestChangedPlugins(
    { plugins: [{ tags: ['a', 'b'], description: 'old', name: 'alpha', version: '1.0.0' }] },
    withMeta,
  ).size === 0,
);

check(
  'a bump with no other change anywhere is not a violation',
  findViolations([], editDesc('1.0.1', 'old'), withMeta).length === 0,
);

console.log(`\n${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
