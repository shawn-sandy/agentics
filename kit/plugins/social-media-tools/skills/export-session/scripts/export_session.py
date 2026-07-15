#!/usr/bin/env python3
"""Convert a Claude Code session JSONL transcript to a Markdown file.

Usage: export_session.py <session.jsonl> <output-dir>
       export_session.py --self-check
Prints the path of the written Markdown file.

ponytail: artifact-tools/skills/session-artifact/scripts/export_session.py is a
deliberate copy of this file, so that plugin installs standalone with no
cross-plugin install-order dependency. Keep the two in sync when either changes.
That copy carries two intentional divergences, both because its output is
published while this one's stays on local disk: it records `source` as the
transcript basename only, and it emits the title as frontmatter `title:` for the
artifact gallery. Title rules are shared and live in that plugin's
references/titles.md.
"""
import json
import re
import sys
import textwrap
from datetime import datetime
from pathlib import Path

TITLE_WIDTH = 60  # shared title rules: artifact-tools/references/titles.md


def title_of(text, width=TITLE_WIDTH):
    """Trim text to a one-line subject, cutting on a word boundary.

    A fallback only: the skill refines this once it has read the whole session.
    It still has to be readable on its own, so it never cuts mid-word.
    """
    # break_on_hyphens=False: the default splits "double-encoded" and leaves a
    # dangling "double-...", which is the mid-word cut this function exists to avoid.
    line = textwrap.shorten(text, width=width, placeholder="...", break_on_hyphens=False)
    if line == "...":
        # shorten collapses to the placeholder alone when the first token is
        # itself longer than width — a URL, a path, a hash. Keep that token whole
        # and let it run past width: half a URL is neither readable nor usable,
        # and "never cut mid-word" is the rule while width is only a target.
        line = " ".join(text.split()).split(" ")[0]
    return line


def text_of(content):
    """Extract readable text from a message content field (string or blocks)."""
    if isinstance(content, str):
        return content.strip()
    parts = []
    for block in content or []:
        if block.get("type") == "text":
            parts.append(block["text"].strip())
        elif block.get("type") == "tool_use":
            parts.append(f"*[tool: {block.get('name', '?')}]*")
    return "\n\n".join(p for p in parts if p)


def main():
    """Read the transcript at argv[1], write a Markdown recap into argv[2].

    Emits YAML frontmatter (session-id, date, source, type) followed by one
    section per conversation turn, and prints the written path.
    """
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, outdir = Path(sys.argv[1]), Path(sys.argv[2])

    turns, session_id, first_ts, first_user = [], None, None, None
    try:
        f = src.open(encoding="utf-8")
    except OSError as e:
        sys.exit(f"Cannot read transcript {src}: {e.strerror or e}")
    with f:
        for line in f:
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            session_id = session_id or rec.get("sessionId")
            first_ts = first_ts or rec.get("timestamp")
            if rec.get("isSidechain") or rec.get("type") not in ("user", "assistant"):
                continue
            msg = rec.get("message") or {}
            content = msg.get("content")
            # skip tool_result-only user records
            if isinstance(content, list) and all(
                b.get("type") == "tool_result" for b in content
            ):
                continue
            text = text_of(content)
            # ponytail: prefix blocklist for harness-injected messages; extend if new tags appear
            if not text or text.startswith(
                ("<system-reminder>", "<command-", "<local-command-", "<task-notification")
            ):
                continue
            role = "User" if rec["type"] == "user" else "Claude"
            if role == "User" and first_user is None:
                first_user = text
            turns.append((role, text))

    if not turns:
        sys.exit(f"No conversation turns found in {src}")

    session_id = session_id or src.stem
    date = (first_ts or datetime.now().isoformat())[:10]
    slug = re.sub(r"[^a-z0-9]+", "-", (first_user or "session").lower()).strip("-")
    slug = "-".join(slug.split("-")[:6]) or "session"
    # short session-id suffix: collision-proof across sessions, idempotent per session
    out = outdir / f"{date}-{slug}-{session_id[:8]}.md"
    outdir.mkdir(parents=True, exist_ok=True)

    # turns is non-empty (guarded above), so there is always a subject to name —
    # a sessionless placeholder like "Session export" is never emitted.
    title = title_of(first_user or turns[0][1])
    body = [
        "---",
        f"session-id: {json.dumps(session_id)}",
        f"date: {date}",
        f"source: {json.dumps(str(src))}",
        "type: session-export",
        "---",
        "",
        f"# Session: {title}",
        "",
    ]
    for role, text in turns:
        body += [f"## {role}", "", text, ""]

    out.write_text("\n".join(body), encoding="utf-8")
    print(out)


def _self_check():
    """Assert title_of never emits a placeholder or a mid-word cut.

    Run: python3 export_session.py --self-check
    """
    long_req = (
        "ensure that the plugins in the artifact-tool always generate a "
        "readable and relevant title for generated artifacts"
    )
    hyphenated = "Rebuilt the plans gallery index and fixed the double-encoded entities."
    url = "https://github.com/shawn-sandy/agentics/blob/main/kit/plugins/artifact-tools/x.md"
    huge = "Supercalifragilisticexpialidociousandthensomemorelettersthatneverendhere"
    for src in (
        "Fix the login redirect",
        long_req,
        hyphenated,
        "  multi\nline\n   input here  ",
        huge,
        url,
        f"{url} please publish this one",
    ):
        got = title_of(src)
        assert got not in ("", "...", "Untitled", "Session export"), f"placeholder: {got!r}"
        assert "\n" not in got, f"multiline: {got!r}"
        words = " ".join(src.split()).split(" ")
        if got.endswith("..."):
            # the kept text must be a whole-word prefix of the collapsed source
            prefixes = {" ".join(words[:i]) for i in range(1, len(words) + 1)}
            assert got[:-3] in prefixes, f"mid-word cut: {got!r}"
            assert len(got) <= TITLE_WIDTH, f"over {TITLE_WIDTH}: {got!r}"
        else:
            # untruncated: either it fit, or it is one oversized whole token
            assert len(got) <= TITLE_WIDTH or got == words[0], f"over {TITLE_WIDTH}: {got!r}"
    assert title_of("Fix the login redirect") == "Fix the login redirect"
    assert title_of(hyphenated) == "Rebuilt the plans gallery index and fixed the..."
    # oversized lone tokens survive intact rather than being sliced mid-token
    assert title_of(url) == url
    assert title_of(f"{url} please publish this one") == url
    assert title_of(huge) == huge
    print("title_of: all checks passed")


if __name__ == "__main__":
    if "--self-check" in sys.argv:
        _self_check()
    else:
        main()
