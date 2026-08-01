# Artifact resolution — the runnable resolver

The precedence rules themselves live in the skill core, where they are always
loaded. This file carries only the script that executes them, because it is
needed once, at Step 6, and only on a run that actually writes an artifact.

Both directories follow Claude Code's settings precedence — project-local
`.claude/settings.local.json`, then project `.claude/settings.json`, then global
`~/.claude/settings.json` — falling back to a `${PWD}` default. The prompts
directory reads `promptsDirectory`; the deprecated proposals directory reads
`planAgent.proposalsDirectory`.

`--dir`, when given, wins over everything below for the **prompts** directory
only. It never redirects the legacy proposals copy: the flag follows the
authoritative artifact.

```bash
python3 - <<'PY'
import json, os
candidates = (
    os.path.join(".claude", "settings.local.json"),
    os.path.join(".claude", "settings.json"),
    os.path.expanduser("~/.claude/settings.json"),
)
def resolve(getter, default):
    for p in candidates:
        try:
            v = (getter(json.load(open(p))) or "").strip()
            if v:
                return v.rstrip("/")
        except Exception:
            continue
    return os.path.join(os.getcwd(), *default)

print(resolve(lambda d: d.get("promptsDirectory"), ("docs", "prompts")))
print(resolve(lambda d: d.get("planAgent", {}).get("proposalsDirectory"),
              ("docs", "proposals")))
PY
```

`mkdir -p` the resolved parent before the first write.

## Why the same key in three places

`prompt` (Phase 7) and `artifact-tools:prompt-artifact` (Step 2) read
`promptsDirectory` with this exact precedence. Diverging here would publish, or
write, to a directory the other two do not agree on — the failure is silent, and
surfaces only as a prompt that cannot be found later.
