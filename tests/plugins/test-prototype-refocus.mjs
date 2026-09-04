#!/usr/bin/env node
/**
 * Regression test for the prototype skeleton's post-submit refocus.
 *
 * After a record is added the submit handler resets the form and moves focus
 * back to the first field. It used to do that with `form.querySelector('input')`,
 * so a prototype whose first field is a <select> (or <textarea>) never got
 * focus back — the keyboard user landed on <body> after every add.
 *
 * Node has no DOM, so this pins the selector list itself: every form-control
 * tag must appear as a simple selector. `document.activeElement` after a real
 * submit is verified in a browser, not here.
 *
 * Run: node tests/plugins/test-prototype-refocus.mjs
 */

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const SKELETON = join(ROOT, 'kit', 'plugins', 'plan-agent', 'skills', 'prototype', 'reference', 'PROTOTYPE-SKELETON.html');

let passed = 0;
function ok(name, fn) {
  try {
    fn();
    passed += 1;
    console.log(`  PASS ${name}`);
  } catch (err) {
    console.error(`  FAIL ${name}`);
    console.error(`       ${err.message}`);
    process.exitCode = 1;
  }
}

const html = readFileSync(SKELETON, 'utf8');
const start = html.indexOf("form.addEventListener('submit'");
const end = html.indexOf('resetBtn.addEventListener', start);
assert.ok(start > -1 && end > start, 'submit handler located in the skeleton');
const handler = html.slice(start, end);

ok('the submit handler refocuses the first field after form.reset()', () => {
  const m = handler.match(/form\.reset\(\);[\s\S]*?form\.querySelector\(\s*(['"])([^'"]+)\1\s*\)[\s\S]*?\.focus\(\)/);
  assert.ok(m, 'form.reset() is followed by form.querySelector(...) and a .focus() call');
});

ok('the refocus selector matches input, select, and textarea as the first field', () => {
  const m = handler.match(/form\.reset\(\);[\s\S]*?form\.querySelector\(\s*(['"])([^'"]+)\1\s*\)/);
  assert.ok(m, 'refocus selector present');
  const parts = m[2].split(',').map((s) => s.trim());
  for (const tag of ['input', 'select', 'textarea']) {
    assert.ok(
      parts.some((p) => new RegExp(`^${tag}(?![\\w-])`).test(p)),
      `selector "${m[2]}" never matches a leading <${tag}>, so that field is skipped after submit`
    );
  }
});

console.log(`\n${passed} passed`);
if (process.exitCode) console.error('FAILURES — see above');
