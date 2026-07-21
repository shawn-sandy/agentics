#!/usr/bin/env python3
"""PreToolUse hook: run the host repo's lint script before a `git commit` lands.

Blocks the commit (exit 2) when lint fails, feeding the output back to Claude so
it can fix and retry without a user round-trip. Every other path is a silent
exit 0 — this hook runs on every Bash call in every repo that installs
git-agent, so anything it does not positively understand must be a no-op.

Detection is package.json only: `scripts.lint`, then `scripts.typecheck`.
Escape hatch: create `.claude/no-lint-gate` at the repo root.
"""
import json
import os
import re
import subprocess
import sys

# `git commit`, allowing global options in between. The value-taking options are
# enumerated so `git -C path commit` matches while `git log --grep commit` does
# not — an unlisted option is still matched as a bare flag.
COMMIT_RE = re.compile(
    r"\bgit\s+"
    r"(?P<opts>(?:(?:-[cC]|--(?:git-dir|work-tree|namespace|exec-path))\s+\S+\s+"
    r"|-{1,2}\S+\s+)*)"
    r"commit(?![\w-])"  # not `commit-tree`: \b would treat the hyphen as a boundary
)
# `-C <path>` retargets the commit at another repo, so the lint root must follow
# it rather than the payload's cwd. Case-sensitive: `-c` is config, not a path.
DASH_C_RE = re.compile(r"(?:^|\s)-C\s+(?P<path>\S+)")

OPT_OUT = os.path.join(".claude", "no-lint-gate")
SCRIPTS = ("lint", "typecheck")
# ponytail: lockfile -> runner. `npm run` mostly works everywhere, but pnpm
# workspaces resolve bins differently and fail confusingly.
RUNNERS = (
    ("pnpm-lock.yaml", ["pnpm", "run"]),
    ("yarn.lock", ["yarn", "run"]),
    ("bun.lock", ["bun", "run"]),   # current format since Bun 1.2
    ("bun.lockb", ["bun", "run"]),  # legacy binary format
)
MAX_OUTPUT = 4000  # keep the blocked-tool message readable
# Both checks must finish inside the hook timeout declared in hooks.json (200s),
# so the per-check budget is capped well under half of it.
PER_CHECK_TIMEOUT = 90
COULD_NOT_RUN = 127  # shell convention for command-not-found
# Evidence that dependencies are installed. `.pnp.cjs` covers Yarn PnP, which
# resolves bins without ever creating node_modules.
DEPS_MARKERS = ("node_modules", ".pnp.cjs")


def repo_root(cwd):
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=cwd, capture_output=True, text=True, timeout=5,
        )
        return out.stdout.strip() if out.returncode == 0 else None
    except Exception:
        return None


def runner(root):
    for lockfile, cmd in RUNNERS:
        if os.path.exists(os.path.join(root, lockfile)):
            return cmd
    return ["npm", "run"]


def main():
    try:
        payload = json.load(sys.stdin)
        if payload.get("tool_name") != "Bash":
            return 0
        command = payload.get("tool_input", {}).get("command") or ""
        if not isinstance(command, str):
            return 0
        match = COMMIT_RE.search(command)
        if not match:
            return 0
        cwd = payload.get("cwd") or os.getcwd()
        # `git -C other/repo commit` commits somewhere else entirely — linting
        # cwd would check the wrong package and let the real one through.
        target = DASH_C_RE.search(match.group("opts"))
        if target:
            cwd = os.path.join(cwd, target.group("path").strip("'\""))
    except Exception:
        return 0

    root = repo_root(cwd)
    if not root or os.path.exists(os.path.join(root, OPT_OUT)):
        return 0

    try:
        with open(os.path.join(root, "package.json")) as fh:
            scripts = json.load(fh).get("scripts") or {}
    except Exception:
        return 0  # no package.json, or unreadable — nothing to run

    # Dependencies not installed yet (fresh clone before `npm install`). The lint
    # script would fail on a missing binary, which is not a code problem — only a
    # check that ran and found something may block.
    if not any(os.path.exists(os.path.join(root, p)) for p in DEPS_MARKERS):
        return 0

    for name in SCRIPTS:
        if name not in scripts:
            continue
        try:
            result = subprocess.run(
                runner(root) + [name],
                cwd=root, capture_output=True, text=True, timeout=PER_CHECK_TIMEOUT,
            )
        except Exception:
            continue  # runner missing or timed out — never strand the commit
        if result.returncode == COULD_NOT_RUN:
            continue  # binary not on PATH; npm/pnpm/yarn pass the shell's 127 through
        if result.returncode != 0:
            output = (result.stdout + result.stderr).strip()[-MAX_OUTPUT:]
            print(
                f"Blocked: `{name}` failed, so this commit was not created.\n\n"
                f"{output}\n\n"
                f"Fix these issues and retry the commit. If this gate is wrong "
                f"for this repo, create {OPT_OUT} to disable it.",
                file=sys.stderr,
            )
            return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
