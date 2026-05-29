#!/usr/bin/env python3
"""
session_usage.py — parse a Claude Code session JSONL and report token usage.

Emits JSON on stdout with token counts, model(s), duration, message/tool-call
counts, and the first user prompt (for the share-session card SUMMARY field).

Usage:
    python3 session_usage.py [<path.jsonl>]

Without an argument: resolves the session from $CLAUDE_CODE_SESSION_ID + the
current working directory (encoded as cwd.replace("/", "-")), then falls back
to the newest-mtime *.jsonl in that project sessions directory.

Defensive by design:
  - Streams line-by-line; sessions can be several MB
  - Tolerates truncated/partial last lines (active sessions)
  - Skips unrecognised event shapes without crashing
"""

from __future__ import annotations

import datetime
import json
import os
import sys
from pathlib import Path


def find_session_file() -> Path | None:
    """Locate the session JSONL via $CLAUDE_CODE_SESSION_ID + cwd, or newest."""
    session_id = os.environ.get("CLAUDE_CODE_SESSION_ID", "")
    encoded = os.getcwd().replace("/", "-")
    sessions_dir = Path.home() / ".claude" / "projects" / encoded

    if session_id and sessions_dir.is_dir():
        candidate = sessions_dir / f"{session_id}.jsonl"
        if candidate.is_file():
            return candidate

    # Fall back to newest-mtime *.jsonl in the project sessions directory
    if sessions_dir.is_dir():
        files = [p for p in sessions_dir.glob("*.jsonl") if p.is_file()]
        if files:
            return max(files, key=lambda p: p.stat().st_mtime)

    return None


def _ts_to_float(ts_str: str) -> float | None:
    """Parse an ISO-8601 timestamp string to a Unix float."""
    try:
        dt = datetime.datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        return dt.timestamp()
    except (ValueError, AttributeError):
        return None


def _extract_user_text(content: object) -> str:
    """Pull plain text from a message content value (list-of-blocks or string)."""
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                text = block.get("text", "").strip()
                if text:
                    return text
    return ""


def parse_session(jsonl_path: Path) -> dict:
    input_tokens = 0
    output_tokens = 0
    cache_write = 0
    cache_read = 0
    models: set = set()
    user_msgs = 0
    assistant_msgs = 0
    tool_calls = 0
    first_ts: float | None = None
    last_ts: float | None = None
    first_user_prompt = ""
    skipped = 0

    with jsonl_path.open("r", encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            raw = raw.strip()
            if not raw:
                continue
            try:
                evt = json.loads(raw)
            except json.JSONDecodeError:
                # Truncated final line or corrupt entry — skip
                skipped += 1
                continue

            if not isinstance(evt, dict):
                continue

            ts_str = evt.get("timestamp", "")
            if ts_str:
                ts = _ts_to_float(ts_str)
                if ts is not None:
                    if first_ts is None or ts < first_ts:
                        first_ts = ts
                    if last_ts is None or ts > last_ts:
                        last_ts = ts

            evt_type = evt.get("type")
            msg = evt.get("message")
            if not isinstance(msg, dict):
                continue

            if evt_type == "user":
                user_msgs += 1
                if not first_user_prompt:
                    text = _extract_user_text(msg.get("content", ""))
                    if text:
                        # Cap at 200 chars; the skill truncates further for the card
                        first_user_prompt = text[:200]

            elif evt_type == "assistant":
                assistant_msgs += 1

                usage = msg.get("usage")
                if isinstance(usage, dict):
                    # int() coercion guards against None, strings, or malformed values
                    input_tokens += int(usage.get("input_tokens") or 0)
                    output_tokens += int(usage.get("output_tokens") or 0)
                    cache_write += int(usage.get("cache_creation_input_tokens") or 0)
                    cache_read += int(usage.get("cache_read_input_tokens") or 0)

                model = msg.get("model")
                if model and isinstance(model, str):
                    models.add(model)

                content = msg.get("content")
                if isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "tool_use":
                            tool_calls += 1

    total_tokens = input_tokens + output_tokens
    cache_total = cache_read + cache_write
    cache_hit_rate = round(cache_read / cache_total * 100, 1) if cache_total > 0 else 0.0

    duration_minutes = 0.0
    if first_ts is not None and last_ts is not None and last_ts > first_ts:
        duration_minutes = round((last_ts - first_ts) / 60, 1)

    first_ts_iso = ""
    if first_ts is not None:
        first_ts_iso = datetime.datetime.fromtimestamp(
            first_ts, tz=datetime.timezone.utc
        ).isoformat()

    return {
        "session_id": jsonl_path.stem,
        "file": str(jsonl_path),
        "total_tokens": total_tokens,
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "cache_write": cache_write,
        "cache_read": cache_read,
        "cache_hit_rate": cache_hit_rate,
        "duration_minutes": duration_minutes,
        "first_timestamp_iso": first_ts_iso,
        "models": sorted(models),
        "user_msgs": user_msgs,
        "assistant_msgs": assistant_msgs,
        "tool_calls": tool_calls,
        "first_user_prompt": first_user_prompt,
        "skipped_lines": skipped,
    }


def main() -> int:
    if len(sys.argv) > 1:
        path = Path(sys.argv[1]).expanduser()
    else:
        path = find_session_file()

    if path is None:
        json.dump(
            {
                "error": "no session file found",
                "hint": "set $CLAUDE_CODE_SESSION_ID or pass an explicit path",
            },
            sys.stdout,
        )
        sys.stdout.write("\n")
        return 1

    if not path.is_file():
        json.dump({"error": f"not a file: {path}"}, sys.stdout)
        sys.stdout.write("\n")
        return 1

    result = parse_session(path)
    json.dump(result, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
