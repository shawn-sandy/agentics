#!/usr/bin/env python3
"""Convert a Claude Code session JSONL transcript to a Markdown file.

Usage: export_session.py <session.jsonl> <output-dir>
Prints the path of the written Markdown file.
"""
import json
import re
import sys
from datetime import datetime
from pathlib import Path


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

    title = (first_user or "Session export").splitlines()[0][:80]
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


if __name__ == "__main__":
    main()
