#!/usr/bin/env python3
"""PreToolUse hook: run the host repo's checks before a `git commit` lands.

Blocks the commit (exit 2) only when the staged index introduces a failure that
HEAD did not already have, feeding the new records back to Claude so it can fix
and retry without a user round-trip. Every path this hook does not positively
understand is a silent exit 0 — it runs on every Bash call in every repo that
installs git-agent.

Check resolution, in order:
  1. `.claude/lint-gate.json` — when present it replaces detection outright.
  2. The nearest manifest walking up from the commit's cwd to the git root:
     package.json (scripts.lint, then scripts.typecheck), pyproject.toml
     (ruff, then flake8), go.mod (go vet), Cargo.toml (cargo clippy).

Escape hatch: create `.claude/no-lint-gate` at the repo root.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
from collections import Counter, namedtuple

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
CONFIG = os.path.join(".claude", "lint-gate.json")
SCRIPTS = ("lint", "typecheck")
# ponytail: lockfile -> runner. `npm run` mostly works everywhere, but pnpm
# workspaces resolve bins differently and fail confusingly.
RUNNERS = (
    ("pnpm-lock.yaml", ["pnpm", "run"]),
    ("yarn.lock", ["yarn", "run"]),
    ("bun.lock", ["bun", "run"]),   # current format since Bun 1.2
    ("bun.lockb", ["bun", "run"]),  # legacy binary format
)
DEFAULT_RUNNER = ["npm", "run"]
# Non-Node ecosystems: manifest -> ordered (probe binary, label, argv). The probe
# is what must be on PATH; `cargo clippy` ships as the separate `cargo-clippy`
# binary, so probing `cargo` would claim a toolchain that cannot run.
ECOSYSTEMS = (
    ("pyproject.toml", (("ruff", "ruff", ["ruff", "check", "."]),
                        ("flake8", "flake8", ["flake8"]))),
    ("go.mod", (("go", "go vet", ["go", "vet", "./..."]),)),
    ("Cargo.toml", (("cargo-clippy", "cargo clippy", ["cargo", "clippy", "--quiet"]),)),
)
MAX_OUTPUT = 4000  # keep the blocked-tool message readable
# Worst case is every check failing and paying for its baseline, plus one
# materialization per side. Test 13 asserts this arithmetic against the timeout
# declared in hooks.json — the harness killing the hook mid-run lets the commit
# through, so the budget must stay under it rather than merely near it.
PER_CHECK_TIMEOUT = 120
BASELINE_TIMEOUT = 60
MATERIALIZE_TIMEOUT = 30
COULD_NOT_RUN = 127  # shell convention for command-not-found
# Evidence that dependencies are installed. `.pnp.cjs` covers Yarn PnP, which
# resolves bins without ever creating node_modules.
DEPS_MARKERS = ("node_modules", ".pnp.cjs")
# Symlinked into both materialized trees so a check does not fail there merely
# for want of dependencies a fresh checkout never has.
DEP_LINKS = ("node_modules", ".pnp.cjs", ".venv", "venv", "target", "vendor")

ANSI_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
DIGITS_RE = re.compile(r"\d+")

# argv is a list when shell is False, a string when True. rel is the check's
# directory relative to the repo root, so the same Check runs against the live
# tree or either materialized tree.
Check = namedtuple("Check", "label argv shell rel")


def git(root, *args, timeout=10):
    try:
        return subprocess.run(
            ["git", *args], cwd=root, capture_output=True, text=True, timeout=timeout,
        )
    except Exception:
        return None


def repo_root(cwd):
    out = git(cwd, "rev-parse", "--show-toplevel", timeout=5)
    return out.stdout.strip() if out and out.returncode == 0 else None


def runner(root):
    for lockfile, cmd in RUNNERS:
        if os.path.exists(os.path.join(root, lockfile)):
            return cmd
    return list(DEFAULT_RUNNER)


def deps_installed(root, d):
    """node_modules is routinely hoisted to a workspace root, so a nested
    package with no local copy is still installed."""
    cur = d
    while True:
        if any(os.path.exists(os.path.join(cur, m)) for m in DEPS_MARKERS):
            return True
        if cur == root:
            return False
        parent = os.path.dirname(cur)
        if parent == cur:
            return False
        cur = parent


def checks_for_dir(root, d):
    rel = os.path.relpath(d, root)
    rel = "" if rel == "." else rel

    # package.json wins where a directory carries more than one manifest.
    try:
        with open(os.path.join(d, "package.json")) as fh:
            scripts = json.load(fh).get("scripts") or {}
    except Exception:
        scripts = {}
    found = [n for n in SCRIPTS if n in scripts]
    if found and deps_installed(root, d):
        run = DEFAULT_RUNNER
        for cand in (d, root):
            picked = runner(cand)
            if picked != DEFAULT_RUNNER:
                run = picked
                break
        return [Check(n, list(run) + [n], False, rel) for n in found]

    for manifest, tools in ECOSYSTEMS:
        if not os.path.exists(os.path.join(d, manifest)):
            continue
        for probe, label, argv in tools:
            if shutil.which(probe):
                return [Check(label, argv, False, rel)]
    return []


def detect(root, cwd):
    """Nearest manifest, walking up from the commit's cwd. The git root is the
    walk's hard ceiling — escaping it would lint a parent project's manifest
    that has nothing to do with this repo."""
    # realpath both sides: `git rev-parse --show-toplevel` resolves symlinks and
    # abspath does not, so on macOS a commit under /tmp (a link to /private/tmp)
    # would look like it sat outside its own repo and fall back to the root.
    root = os.path.realpath(root)
    d = os.path.realpath(cwd)
    try:
        inside = os.path.commonpath([root, d]) == root
    except ValueError:  # different drives on Windows
        inside = False
    if not inside:
        d = root
    while True:
        checks = checks_for_dir(root, d)
        if checks:
            return checks
        if d == root:
            return []
        parent = os.path.dirname(d)
        if parent == d:
            return []
        d = parent


def config_checks(root):
    """(present, checks). `present` is True whenever the file exists, so a
    malformed config disables the gate rather than silently falling back to
    detection the author meant to replace."""
    path = os.path.join(root, CONFIG)
    if not os.path.exists(path):
        return False, []
    try:
        with open(path) as fh:
            commands = json.load(fh).get("commands") or []
        if isinstance(commands, str):
            commands = [commands]
        commands = [c for c in commands if isinstance(c, str) and c.strip()]
    except Exception:
        return True, []
    return True, [Check(c, c, True, "") for c in commands]


def run_check(check, base, timeout):
    cwd = os.path.join(base, check.rel) if check.rel else base
    if not os.path.isdir(cwd):
        return None
    env = dict(os.environ, NO_COLOR="1", FORCE_COLOR="0")
    try:
        return subprocess.run(
            check.argv, cwd=cwd, shell=check.shell, env=env,
            capture_output=True, text=True, timeout=timeout,
        )
    except Exception:
        return None  # runner missing or timed out — never strand the commit


def output_of(result):
    return (result.stdout + result.stderr).strip()


def records(text, strip):
    """Digit-masked, path-stripped line multiset, plus one raw sample per key.

    Deliberately linter-agnostic: no per-tool output parser and no
    machine-readable format flag, neither of which survives a repo whose lint
    script wraps the tool. Masking digits absorbs the line-number shift an edit
    causes further down a file, and comparing *counts* keeps that from hiding a
    genuinely new occurrence — adding one always raises its key's count.
    """
    counts, sample = Counter(), {}
    for line in text.splitlines():
        line = ANSI_RE.sub("", line)
        if strip:
            line = line.replace(strip, "")
        line = " ".join(line.split())
        if not line:
            continue
        key = DIGITS_RE.sub("N", line)
        counts[key] += 1
        sample.setdefault(key, line)
    return counts, sample


def new_records(index_text, index_root, head_text, head_root):
    index_counts, sample = records(index_text, index_root)
    head_counts, _ = records(head_text, head_root)
    return [sample[k] for k, n in index_counts.items() if n > head_counts.get(k, 0)]


def materialize(root, treeish, dest, workdir):
    """Extract a tree-ish into dest. `git archive` plus stdlib tarfile avoids
    registering a worktree, so a crash here leaves no bookkeeping behind."""
    tar = os.path.join(workdir, "tree.tar")
    result = git(root, "archive", "--format=tar", "-o", tar, treeish,
                 timeout=MATERIALIZE_TIMEOUT)
    if not result or result.returncode != 0:
        return False
    try:
        os.makedirs(dest, exist_ok=True)
        with tarfile.open(tar) as tf:
            try:
                tf.extractall(dest, filter="data")
            except TypeError:  # filter= predates neither 3.11.4 nor 3.12
                tf.extractall(dest)
    except Exception:
        return False
    finally:
        try:
            os.remove(tar)
        except OSError:
            pass
    return True


def ancestors(rel):
    """Every directory between `rel` and the repo root, root ("") included."""
    out = {""}
    while rel:
        out.add(rel)
        rel = os.path.dirname(rel)
    return out


def link_deps(root, dest, rels):
    """A fresh checkout has no dependencies, so a check there would fail on a
    missing binary and read as 'HEAD was already broken' — which would pass
    every real failure. Accepted limitation: a dependency change staged in the
    commit is not reflected on the HEAD side, so a failure caused purely by a
    dependency bump reads as pre-existing.
    Every ancestor of every check is linked, not just the check's own directory:
    `deps_installed` accepts an install anywhere up the tree, so linking less
    than it accepts would let a hoisted-workspace repo materialize without its
    dependencies, fail the check on a missing binary, and read that 127 as
    "could not run" — silently passing a real failure."""
    for rel in set(rels) | {a for rel in rels for a in ancestors(rel)}:
        for name in DEP_LINKS:
            src = os.path.join(root, rel, name) if rel else os.path.join(root, name)
            if not os.path.exists(src):
                continue
            dst = os.path.join(dest, rel, name) if rel else os.path.join(dest, name)
            if os.path.exists(dst) or os.path.islink(dst):
                continue
            try:
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                os.symlink(src, dst)
            except OSError:
                pass


def index_matches_worktree(root):
    """Column 2 of porcelain is the worktree-vs-index status; `??` trips it too,
    since an untracked file is not in the index but a whole-directory linter
    would still read it."""
    result = git(root, "status", "--porcelain")
    if not result or result.returncode != 0:
        return False
    return all(len(l) < 2 or l[1] == " " for l in result.stdout.splitlines())


def has_head(root):
    result = git(root, "rev-parse", "--verify", "-q", "HEAD", timeout=5)
    return bool(result and result.returncode == 0)


def block(label, body, degraded=False):
    note = (
        "\n\nThe pre-change baseline could not be established, so the whole "
        "check output is shown and every failure blocks."
        if degraded else ""
    )
    print(
        f"Blocked: `{label}` failed, so this commit was not created.\n\n"
        f"{body.strip()[-MAX_OUTPUT:]}{note}\n\n"
        f"Fix these issues and retry the commit. If this gate is wrong "
        f"for this repo, create {OPT_OUT} to disable it.",
        file=sys.stderr,
    )
    return 2


def gate(root, cwd, workdir):
    present, checks = config_checks(root)
    if not present:
        checks = detect(root, cwd)
    if not checks:
        return 0

    # An unborn branch has nothing to compare against, so every failure is new
    # by definition and the gate stays in the working tree.
    baseline = has_head(root)
    index_root, degraded = root, False
    if baseline and not index_matches_worktree(root):
        # Pin the verdict to what is being committed. Comparing a live working
        # tree races against concurrent edits and would judge unstaged work.
        tree = git(root, "write-tree")
        staged = os.path.join(workdir, "index")
        if tree and tree.returncode == 0 and materialize(
            root, tree.stdout.strip(), staged, workdir
        ):
            link_deps(root, staged, sorted({c.rel for c in checks}))
            index_root = staged
        else:
            degraded = True  # fall back to whole-project blocking, never to off

    head_root = None
    for check in checks:
        primary = run_check(check, index_root, PER_CHECK_TIMEOUT)
        if primary is None or primary.returncode in (0, COULD_NOT_RUN):
            continue  # passed, or could not run at all — only a real finding blocks
        body = output_of(primary)
        if not baseline or degraded:
            return block(check.label, body, degraded=degraded)

        if head_root is None:
            head_root = os.path.join(workdir, "head")
            if materialize(root, "HEAD", head_root, workdir):
                link_deps(root, head_root, sorted({c.rel for c in checks}))
            else:
                head_root = False
        if head_root is False:
            return block(check.label, body, degraded=True)

        before = run_check(check, head_root, BASELINE_TIMEOUT)
        if before is None:
            return block(check.label, body, degraded=True)
        # The check passed at HEAD and fails now: the commit broke it, whatever
        # the output looks like. Deciding this on exit status rather than on
        # records closes every normalization blind spot at once — a check that
        # fails silently, and one whose only difference is a digit the mask
        # erases ("0 problems" vs "3 problems"), both reach here with nothing
        # the record comparison can call new.
        if before.returncode == 0:
            return block(
                check.label,
                body or f"`{check.label}` exited {primary.returncode} with no output.",
            )
        new = new_records(body, index_root, output_of(before), head_root)
        if new:
            return block(check.label, "\n".join(new))
    return 0


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
            return 0  # nothing below this line may run for a non-commit call
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

    workdir = tempfile.mkdtemp(prefix="lint-gate-")
    try:
        return gate(root, cwd, workdir)
    except Exception:
        return 0
    finally:
        # rmtree unlinks symlinks rather than following them, so the host's real
        # node_modules is never at risk here.
        shutil.rmtree(workdir, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
