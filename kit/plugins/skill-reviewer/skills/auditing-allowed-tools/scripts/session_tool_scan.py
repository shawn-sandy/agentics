#!/usr/bin/env python3
"""
session_tool_scan.py — parse a Claude Code session JSONL and report tool usage.

Emits a JSON summary on stdout with per-tool call counts and a per-command
breakdown for Bash. Used by the `auditing-allowed-tools` skill to compare a
skill's declared `allowed-tools` against what Claude actually invoked.

Usage:
    python3 session_tool_scan.py <path.jsonl> [--include-subagents]

Defensive by design:
  - Streams input line-by-line (sessions can be several MB)
  - Tolerates truncated/partial last lines (active sessions)
  - Skips unrecognized event shapes rather than crashing
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter
from pathlib import Path


def iter_tool_uses(jsonl_path: Path):
    """Yield (tool_name, input_dict) for every tool_use event in the file."""
    with jsonl_path.open("r", encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            raw = raw.strip()
            if not raw:
                continue
            try:
                evt = json.loads(raw)
            except json.JSONDecodeError:
                # Truncated final line or corrupt entry — skip.
                yield ("__skip__", None)
                continue

            msg = evt.get("message") if isinstance(evt, dict) else None
            if not isinstance(msg, dict):
                continue
            content = msg.get("content")
            if not isinstance(content, list):
                continue
            for block in content:
                if not isinstance(block, dict):
                    continue
                if block.get("type") != "tool_use":
                    continue
                name = block.get("name")
                if not isinstance(name, str):
                    continue
                yield (name, block.get("input") or {})


def summarize(jsonl_path: Path) -> dict:
    tools: dict[str, dict] = {}
    bash_cmds: Counter = Counter()
    total = 0
    skipped = 0

    for name, inp in iter_tool_uses(jsonl_path):
        if name == "__skip__":
            skipped += 1
            continue
        total += 1
        entry = tools.setdefault(name, {"count": 0})
        entry["count"] += 1
        if name == "Bash" and isinstance(inp, dict):
            cmd = inp.get("command", "")
            if isinstance(cmd, str) and cmd.strip():
                first = cmd.strip().split()[0]
                # Strip common prefixes
                if first in ("sudo", "time"):
                    parts = cmd.strip().split()
                    first = parts[1] if len(parts) > 1 else first
                bash_cmds[first] += 1

    if "Bash" in tools and bash_cmds:
        tools["Bash"]["commands"] = dict(bash_cmds.most_common())

    return {
        "file": str(jsonl_path),
        "tool_calls_total": total,
        "skipped_lines": skipped,
        "tools": tools,
    }


def merge(base: dict, extra: dict) -> dict:
    base["tool_calls_total"] += extra["tool_calls_total"]
    base["skipped_lines"] += extra["skipped_lines"]
    for name, data in extra["tools"].items():
        target = base["tools"].setdefault(name, {"count": 0})
        target["count"] += data["count"]
        if "commands" in data:
            merged = Counter(target.get("commands", {}))
            merged.update(data["commands"])
            target["commands"] = dict(merged.most_common())
    return base


def recommend_allowed_tools(summary: dict) -> str:
    """Build a minimal comma-separated allowed-tools line from observed usage."""
    names = sorted(summary["tools"].keys())
    if not names:
        return ""
    parts: list[str] = []
    for name in names:
        if name == "Bash":
            cmds = summary["tools"][name].get("commands", {})
            roots = set(cmds.keys())
            # If exactly one CLI family, suggest restricted form.
            if len(roots) == 1:
                (only,) = roots
                parts.append(f"Bash({only} *)")
            else:
                parts.append("Bash")
        else:
            parts.append(name)
    return ", ".join(parts)


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="Scan a Claude Code session JSONL for tool usage.")
    ap.add_argument("path", help="Path to the session .jsonl file")
    ap.add_argument(
        "--include-subagents",
        action="store_true",
        help="Also scan <session-dir>/<session-uuid>/subagents/*.jsonl",
    )
    args = ap.parse_args(argv)

    jsonl_path = Path(args.path).expanduser()
    if not jsonl_path.is_file():
        print(f"error: not a file: {jsonl_path}", file=sys.stderr)
        return 2

    summary = {
        "file": str(jsonl_path),
        "session_id": jsonl_path.stem,
        "tool_calls_total": 0,
        "skipped_lines": 0,
        "tools": {},
        "subagent_files_scanned": 0,
    }
    summary = merge(summary, summarize(jsonl_path))
    summary["session_id"] = jsonl_path.stem

    if args.include_subagents:
        sub_dir = jsonl_path.parent / jsonl_path.stem / "subagents"
        if sub_dir.is_dir():
            for sub in sorted(sub_dir.glob("*.jsonl")):
                summary = merge(summary, summarize(sub))
                summary["subagent_files_scanned"] += 1

    summary["recommended_allowed_tools"] = recommend_allowed_tools(summary)
    json.dump(summary, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
