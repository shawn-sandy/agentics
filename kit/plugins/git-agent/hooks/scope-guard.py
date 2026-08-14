#!/usr/bin/env python3
"""PreToolUse hook: refuse commands whose blast radius exceeds their intent.

Two rules, each backed by a recorded incident:

  1. A formatter or linter run with `--write`/`--fix` over the whole tree —
     typed directly, or reached through a package script such as
     `npm run fix:all`. One such run reformatted ~190 untouched files and
     needed a guarded revert.
  2. `git stash pop` / `git stash apply` with no stash reference. One bare pop
     restored an unrelated stash and created conflicts needing recovery.

Nothing else is blocked. `rm`, `curl`, `git reset --hard`, and
`git checkout -- .` are deliberately out of scope: a guard that fires on safe
commands gets switched off within a week, which costs more than the two
patterns it was catching.

Package scripts are resolved before matching, because the command that caused
the incident — `npm run fix:all` — carries none of the dangerous text itself.
Resolution strips an optional `run` token rather than enumerating invocation
spellings: `yarn fix:all` and `yarn run fix:all` are the same command, so a
list of literal forms would leave a bypass for whichever one it omitted.

This hook runs on every Bash call in every repo that installs git-agent, so
every path it does not positively understand is a silent exit 0, and nothing
touches the filesystem until a command is a genuine candidate. A blocked
pattern quoted inside a `git commit -m` message, an `echo`, or a `grep`
argument is a mention, not an invocation, and never matches.

Escape hatch: create `.claude/no-scope-guard` at the repo root.
"""
import json
import os
import shlex
import subprocess
import sys
from collections import namedtuple

OPT_OUT = os.path.join(".claude", "no-scope-guard")
MANIFEST = "package.json"

# Package-script runners. `run` is optional after each of them.
RUNNERS = ("npm", "pnpm", "yarn", "bun")
RUN_WORDS = ("run", "run-script")
# One-off package executors: `npx prettier ...` is a prettier invocation.
EXECUTORS = ("npx", "pnpx", "bunx")
# Runner sub-commands that mean "execute this package", not "run a script".
EXEC_WORDS = ("dlx", "exec", "x")
# Tools whose --write/--fix rewrites files in place. Deliberately short: this
# is the list with recorded incidents, not every tool that could rewrite.
FORMATTERS = ("prettier", "biome", "eslint")
FIX_FLAGS = ("--write", "--fix")
# Operands meaning "the whole tree". A path that merely contains a dot
# (`.prettierrc`, `./src`, `src/app.ts`) is scoped and never matches.
REPO_WIDE = (".", "./", "..", "../")
STASH_VERBS = ("pop", "apply")

# Cheap pre-filter over the raw text, before any parsing. A command with none
# of these and no runner word cannot reach either rule.
TRIGGERS = ("--write", "--fix", "stash")

# Shell operators, matched as whole tokens only — a `;` or `&&` inside a quoted
# string is part of its argument and must not split anything.
SEPARATORS = ("&&", "||", ";", ";;", "|", "&")

# git global options that consume the next token, so `git -C path stash pop`
# finds `stash` rather than reading `path` as the sub-command.
GIT_VALUE_OPTS = ("-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path")

# `fix:all` -> `format` -> `prettier --write .` is two hops; the cap is what
# stops a self-referential script (`"a": "npm run a"`) from recursing forever.
MAX_DEPTH = 3

# `offending` is the command the rule actually matched, which differs from the
# typed one whenever a package script was resolved.
Violation = namedtuple("Violation", "rule offending body")


def triggered(command):
    """Raw-text pre-filter. Generous on purpose — `is_candidate` is the real
    gate, and being generous here only costs a shlex parse."""
    if any(token in command for token in TRIGGERS):
        return True
    return any(os.path.basename(word) in RUNNERS for word in command.split())


def segments(tokens):
    """Split a token list on shell operators into separate commands."""
    out, current = [], []
    for token in tokens:
        if token in SEPARATORS:
            if current:
                out.append(current)
            current = []
        else:
            current.append(token)
    if current:
        out.append(current)
    return out


def normalize(tokens):
    """Strip leading `VAR=value` assignments and package-executor prefixes, so
    the head token is the program actually being invoked."""
    toks = list(tokens)
    while toks and not toks[0].startswith("-") and "=" in toks[0] \
            and toks[0].split("=", 1)[0].isidentifier():
        toks = toks[1:]
    while toks:
        head = os.path.basename(toks[0])
        if head in EXECUTORS:
            toks = toks[1:]
            while toks and toks[0].startswith("-"):
                toks = toks[1:]
            continue
        if head in RUNNERS and len(toks) > 1 and toks[1] in EXEC_WORDS:
            toks = toks[2:]
            continue
        break
    return toks


def git_args(tokens):
    """Positional arguments after `git`, with global options removed."""
    out, i = [], 1
    while i < len(tokens):
        token = tokens[i]
        if token in GIT_VALUE_OPTS:
            i += 2
            continue
        if token.startswith("-"):
            i += 1
            continue
        out.append(token)
        i += 1
    return out


def is_candidate(tokens):
    """True only for an invocation one of the rules could match.

    `git` is admitted solely for `git stash`, which is what keeps a blocked
    pattern quoted inside `git commit -m "..."` from reaching the filesystem
    at all — the observed false positive that gets a guard disabled."""
    if not tokens:
        return False
    head = os.path.basename(tokens[0])
    if head in RUNNERS or head in FORMATTERS:
        return True
    if head == "git":
        args = git_args(tokens)
        return bool(args) and args[0] == "stash"
    return False


def render(tokens):
    return " ".join(shlex.quote(t) if " " in t else t for t in tokens)


def repo_root(cwd):
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=cwd, capture_output=True, text=True, timeout=5,
        )
    except Exception:
        return None
    return result.stdout.strip() if result.returncode == 0 else None


def walk_up(root, cwd):
    """Directories from `cwd` up to the git root, inclusive. The root is a hard
    ceiling — escaping it would read a parent project's manifest."""
    root = os.path.realpath(root)
    directory = os.path.realpath(cwd)
    try:
        inside = os.path.commonpath([root, directory]) == root
    except ValueError:  # different drives on Windows
        inside = False
    if not inside:
        directory = root
    out = []
    while True:
        out.append(directory)
        if directory == root:
            return out
        parent = os.path.dirname(directory)
        if parent == directory:
            return out
        directory = parent


def read_scripts(path):
    """A manifest's `scripts` map, or empty. Unreadable or malformed JSON is
    an empty map, never a block."""
    try:
        with open(path) as handle:
            data = json.load(handle)
    except Exception:
        return {}
    scripts = data.get("scripts") if isinstance(data, dict) else None
    return scripts if isinstance(scripts, dict) else {}


def resolve_script(tokens, root, cwd):
    """The body of the package script a runner invocation names, or None.

    The optional `run` token is stripped rather than required, so all eight
    spellings (`npm`/`pnpm`/`yarn`/`bun`, each with and without `run`) resolve
    identically. A missing manifest, malformed JSON, or absent script resolves
    to nothing and never blocks on its own."""
    args = [t for t in tokens[1:] if not t.startswith("-")]
    if args and args[0] in RUN_WORDS:
        args = args[1:]
    if not args:
        return None
    name = args[0]
    for directory in walk_up(root, cwd):
        body = read_scripts(os.path.join(directory, MANIFEST)).get(name)
        if isinstance(body, str) and body.strip():
            return body
    return None


def formatter_violation(tokens):
    """Block a formatter or linter whose operand is the whole tree.

    The constraint is blast radius, not the tool: `prettier --write src/app.ts`
    is the documented correct action and must stay frictionless."""
    if not any(t.split("=", 1)[0] in FIX_FLAGS for t in tokens[1:]):
        return None
    operands = [t for t in tokens[1:] if not t.startswith("-")]
    if operands and not any(o in REPO_WIDE for o in operands):
        return None
    scope = "no path operand" if not operands else "`.` as its path"
    return Violation(
        rule="repo-wide formatter",
        offending=render(tokens),
        body=(
            "Rule: a formatter or linter run with --write/--fix and {scope} "
            "rewrites every file in the tree. One such run reformatted ~190 "
            "untouched files and needed a guarded revert.\n\n"
            "Instead, format only what you changed:\n"
            "    npx {tool} {flag} <path> [<path> ...]\n\n"
            "A repo-wide run is a deliberate, separate change — ask first."
        ).format(
            scope=scope,
            tool=os.path.basename(tokens[0]),
            flag=next(t for t in tokens[1:] if t.split("=", 1)[0] in FIX_FLAGS),
        ),
    )


def stash_violation(tokens):
    """Block `git stash pop`/`apply` with no explicit stash reference."""
    args = git_args(tokens)
    if len(args) < 2 or args[0] != "stash" or args[1] not in STASH_VERBS:
        return None
    if len(args) > 2:
        return None  # an explicit stash@{N} or index was given
    return Violation(
        rule="index-less stash pop",
        offending=render(tokens),
        body=(
            "Rule: `git stash {verb}` with no stash reference takes whichever "
            "entry is on top, which is not necessarily the one you saved. A "
            "bare pop restored an unrelated stash and created conflicts "
            "needing recovery.\n\n"
            "Instead, list first and {verb} by explicit index:\n"
            "    git stash list\n"
            "    git stash {verb} stash@{{N}}"
        ).format(verb=args[1]),
    )


def evaluate(tokens, root, cwd, depth=0):
    """The first violation this segment carries, or None."""
    tokens = normalize(tokens)
    if not tokens:
        return None
    head = os.path.basename(tokens[0])
    if head in RUNNERS:
        if depth >= MAX_DEPTH:
            return None
        body = resolve_script(tokens, root, cwd)
        if not body:
            return None
        try:
            inner = shlex.split(body)
        except ValueError:
            return None
        for segment in segments(inner):
            found = evaluate(segment, root, cwd, depth + 1)
            if found:
                return found
        return None
    if head in FORMATTERS:
        return formatter_violation(tokens)
    if head == "git":
        return stash_violation(tokens)
    return None


def message(typed, violation):
    lead = "`%s`" % typed
    if violation.offending != typed:
        lead = "`%s`, which runs `%s`" % (typed, violation.offending)
    return (
        "Blocked ({rule}): {lead}\n\n{body}\n\n"
        "If this guard is wrong for this repo, create {opt_out} at the repo "
        "root to disable it."
    ).format(
        rule=violation.rule, lead=lead, body=violation.body, opt_out=OPT_OUT,
    )


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    if not isinstance(payload, dict) or payload.get("tool_name") != "Bash":
        return 0
    tool_input = payload.get("tool_input")
    command = tool_input.get("command") if isinstance(tool_input, dict) else None
    if not isinstance(command, str) or not command.strip():
        return 0
    if not triggered(command):
        return 0
    try:
        tokens = shlex.split(command)
    except ValueError:
        return 0  # unbalanced quotes: not a command this hook can reason about
    candidates = [s for s in (normalize(seg) for seg in segments(tokens))
                  if is_candidate(s)]
    if not candidates:
        return 0

    # Only now is the filesystem in play. Resolve the repo and honour the
    # opt-out before any rule runs.
    cwd = payload.get("cwd") or os.getcwd()
    try:
        root = repo_root(cwd) or cwd
        if os.path.exists(os.path.join(root, OPT_OUT)):
            return 0
        for segment in candidates:
            violation = evaluate(segment, root, cwd)
            if violation:
                print(message(render(segment), violation), file=sys.stderr)
                return 2
    except Exception:
        return 0  # never fail a Bash call because this guard misparsed
    return 0


if __name__ == "__main__":
    sys.exit(main())
