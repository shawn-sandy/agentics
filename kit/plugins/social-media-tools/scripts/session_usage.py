#!/usr/bin/env python3
"""
session_usage.py — parse a Claude Code session JSONL and report token usage.

Emits JSON on stdout with token counts, model(s), duration, message/tool-call
counts, the first user prompt, and content signals for summarization.

The content signals — `user_prompts`, `assistant_snippets`, `tool_use_counts`,
and `files_touched` — exist so background-mode callers (which do not share the
live session's conversation context) can reconstruct a faithful summary of what
the session accomplished. Interactive callers summarize from their own context
and use these mainly as corroborating detail.

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


# Caps keep stdout bounded on long (multi-MB) sessions. Early prompts carry the
# session's intent; a dozen assistant snippets cover the running narration; 40
# distinct files is more than enough to characterise the work.
MAX_PROMPTS = 8
MAX_SNIPPETS = 12
MAX_FILES = 40
SNIP_LEN = 280
# Tools whose input names a file we count as "touched" (i.e. changed/created).
FILE_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}


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

    # Content signals for summarization (see module docstring).
    user_prompts: list[str] = []
    assistant_snippets: list[str] = []
    tool_use_counts: dict[str, int] = {}
    files_touched: list[str] = []
    _files_seen: set[str] = set()

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
                text = _extract_user_text(msg.get("content", ""))
                # Skip Claude Code's synthetic user turns — tool_result echoes
                # (already "" from _extract_user_text) plus <system-reminder>,
                # <command-message>, <local-command-stdout> and similar injected
                # blocks — so prompts reflect the developer's actual requests and
                # don't waste the small cap on internal noise.
                if text and not text.startswith("<"):
                    if not first_user_prompt:
                        # Cap at 200 chars; the skill truncates further for the card
                        first_user_prompt = text[:200]
                    if len(user_prompts) < MAX_PROMPTS:
                        user_prompts.append(text[:SNIP_LEN])

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
                        if not isinstance(block, dict):
                            continue
                        btype = block.get("type")
                        if btype == "tool_use":
                            tool_calls += 1
                            name = block.get("name")
                            if isinstance(name, str) and name:
                                tool_use_counts[name] = tool_use_counts.get(name, 0) + 1
                                if name in FILE_TOOLS:
                                    inp = block.get("input")
                                    if isinstance(inp, dict):
                                        fp = (
                                            inp.get("file_path")
                                            or inp.get("path")
                                            or inp.get("notebook_path")
                                        )
                                        if (
                                            isinstance(fp, str)
                                            and fp
                                            and fp not in _files_seen
                                        ):
                                            _files_seen.add(fp)
                                            if len(files_touched) < MAX_FILES:
                                                files_touched.append(fp)
                        elif btype == "text" and len(assistant_snippets) < MAX_SNIPPETS:
                            t = block.get("text", "")
                            if isinstance(t, str):
                                t = t.strip()
                                if t:
                                    assistant_snippets.append(t[:SNIP_LEN])

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
        "user_prompts": user_prompts,
        "assistant_snippets": assistant_snippets,
        "tool_use_counts": tool_use_counts,
        "files_touched": files_touched,
        # True unique count from the full set — `files_touched` is capped at
        # MAX_FILES for output size, so its length would under-report long sessions.
        "files_touched_count": len(_files_seen),
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
