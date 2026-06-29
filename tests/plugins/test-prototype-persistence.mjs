#!/usr/bin/env node
// Persistence test for the prototype skeleton's store logic (load/save/resetStore).
// Drives the real extracted store code with a tiny in-memory localStorage shim and
// a minimal document#seed shim — no jsdom, no added dependency.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import assert from 'node:assert/strict';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const SKEL = join(ROOT, 'kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html');

const html = readFileSync(SKEL, 'utf8');

// Extract the marked, extractable STORE block from the skeleton.
const m = html.match(/=== STORE \(extractable[^\n]*===\s*\*\/([\s\S]*?)\/\* === END STORE ===/);
assert.ok(m, 'STORE block not found in skeleton — extraction markers missing');
const storeBlock = m[1];

// One shared localStorage shim so isolation between prototypes is real.
function makeLocalStorage() {
  const map = new Map();
  return {
    getItem: (k) => (map.has(k) ? map.get(k) : null),
    setItem: (k, v) => map.set(k, String(v)),
    removeItem: (k) => map.delete(k),
  };
}

// Build a store instance bound to a STORE_KEY + seed, sharing the given localStorage.
function makeStore(localStorage, key, seedJson, confirmReturns = true) {
  const block = storeBlock.replace('{{STORE_KEY}}', key);
  const doc = { getElementById: () => ({ textContent: seedJson }) };
  const factory = new Function(
    'localStorage', 'confirm', 'document',
    block + '\n return { load, save, resetStore, readSeed, STORE_KEY };'
  );
  return factory(localStorage, () => confirmReturns, doc);
}

const seedA = '[{"name":"a1"},{"name":"a2"}]';
const seedB = '[{"name":"b1"},{"name":"b2"},{"name":"b3"}]';

let passed = 0;
function check(label, fn) { fn(); passed++; console.log('  PASS ' + label); }

console.log('=== prototype persistence test ===');

const ls = makeLocalStorage();
const A = makeStore(ls, 'proto:a', seedA);
const B = makeStore(ls, 'proto:b', seedB);

check('1. seed parses and loads on first call', () => {
  assert.equal(A.load().length, 2);
  assert.equal(B.load().length, 3);
});

check('2. adds persist under the namespaced key', () => {
  const recs = A.load();
  recs.push({ name: 'a3' });
  A.save(recs);
  assert.equal(A.load().length, 3);
  assert.ok(ls.getItem('proto:a'), 'key proto:a not written');
});

check("3. two prototypes don't share state", () => {
  // A now has 3 saved; B was never written, still falls back to its own seed.
  assert.equal(B.load().length, 3);          // B's seed length, not A's saved data
  assert.equal(ls.getItem('proto:b'), null); // B never persisted
  assert.notEqual(A.load()[2].name, 'b1');
});

check('4. reset restores the seed and clears the key', () => {
  const restored = A.resetStore();
  assert.equal(restored.length, 2);          // back to seedA
  assert.equal(ls.getItem('proto:a'), null);
  assert.equal(A.load().length, 2);
});

check('5. reset is cancellable via confirm', () => {
  const ls2 = makeLocalStorage();
  const C = makeStore(ls2, 'proto:c', seedA, /* confirmReturns */ false);
  const recs = C.load(); recs.push({ name: 'x' }); C.save(recs);
  assert.equal(C.resetStore(), null);        // user cancelled
  assert.equal(C.load().length, 3);          // changes kept
});

console.log(`\nAll ${passed} persistence checks passed.`);
