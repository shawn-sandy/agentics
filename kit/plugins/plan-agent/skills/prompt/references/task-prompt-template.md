# Task Prompt Template

Used by `prompt` for **task** prompt type.

Techniques applied: Clarity/directness · XML context + example tags · Thinking/CoT scaffolding · Output format

---

## Template

```text
<context>
{{TASK_CONTEXT}}
</context>

<example>
<input>{{EXAMPLE_INPUT}}</input>
<output>{{EXAMPLE_OUTPUT}}</output>
</example>

<thinking>
Before writing your response, work through this step by step:
1. {{REASONING_STEP_1}}
2. {{REASONING_STEP_2}}
3. Check: {{SELF_CHECK_QUESTION}}
</thinking>

{{CORE_INSTRUCTION}}

Output requirements:
- Format: {{OUTPUT_FORMAT}}
- Length: {{OUTPUT_LENGTH}}
- Tone: {{OUTPUT_TONE}}
```

**The `<example>` and `<thinking>` blocks are optional.** Include the example
only when the output requirements cannot express what it shows — a tone, a
layout, an edge-case judgment; one pair is usually enough. Include the thinking
block only when the *shape* of the reasoning matters, such as a required order
of checks. Delete the block rather than fill it with invented reasoning steps:
per section 0 of `best-practices-reference.md`, scaffolding the model did not
need is one more thing for it to reconcile.

---

## Placeholder Guide

| Placeholder | Source | Example |
|-------------|--------|---------|
| TASK_CONTEXT | Interview: input description + motivation | "You are refactoring a Python module that handles user authentication. The goal is to improve readability and reduce coupling, not change behavior." |
| EXAMPLE_INPUT | Interview: edge case or typical input | "A 50-line `login()` function that calls the database, validates the token, and logs the event in a single block" |
| EXAMPLE_OUTPUT | Interview: desired output description | "Three separate functions: `validate_credentials()`, `issue_token()`, and `log_auth_event()`, each under 15 lines" |
| REASONING_STEP_1 | Derived from task type | "Identify the distinct responsibilities in the provided code" |
| REASONING_STEP_2 | Derived from task type | "Determine the minimal interface each responsibility needs" |
| SELF_CHECK_QUESTION | Interview: failure mode answer | "Would someone unfamiliar with this codebase understand what each function does from its name alone?" |
| CORE_INSTRUCTION | Interview: task description | "Refactor the provided Python function into well-named, single-responsibility functions. Do not change behavior." |
| OUTPUT_FORMAT | Interview: output format answer | "Python code blocks with no surrounding explanation" |
| OUTPUT_LENGTH | Interview: length constraints | "As short as needed — no padding or summaries" |
| OUTPUT_TONE | Interview: tone answer | "Technical, precise" |

---

## Assembled Example

```text
<context>
You are refactoring a Python authentication module. The goal is to improve readability and reduce coupling between responsibilities — do not change observable behavior or public API signatures.
</context>

<example>
<input>
def login(username, password, db):
    user = db.query(f"SELECT * FROM users WHERE username='{username}'")
    if not user or not check_password(password, user.password_hash):
        log("login_failed", username)
        return None
    token = generate_token(user.id)
    db.execute(f"INSERT INTO sessions VALUES ('{token}', {user.id})")
    log("login_success", username)
    return token
</input>
<output>
def validate_credentials(username: str, password: str, db) -> Optional[User]:
    user = db.query_one("SELECT * FROM users WHERE username = %s", (username,))
    if not user or not check_password(password, user.password_hash):
        return None
    return user

def create_session(user_id: int, db) -> str:
    token = generate_token(user_id)
    db.execute("INSERT INTO sessions VALUES (%s, %s)", (token, user_id))
    return token

def log_auth_event(event: str, username: str) -> None:
    log(event, username)

def login(username: str, password: str, db) -> Optional[str]:
    user = validate_credentials(username, password, db)
    if user is None:
        log_auth_event("login_failed", username)
        return None
    token = create_session(user.id, db)
    log_auth_event("login_success", username)
    return token
</output>
</example>

<thinking>
Before writing your response, work through this step by step:
1. Identify the distinct responsibilities in the provided code (credential check, session creation, audit logging)
2. Determine the minimal parameters each responsibility needs — avoid threading the full db object through everything
3. Check: would someone unfamiliar with this codebase understand what each function does from its name alone?
</thinking>

Refactor the provided Python function(s) into well-named, single-responsibility functions following the patterns shown in the example. Do not change observable behavior or public API signatures.

Output requirements:
- Format: Python code blocks only, no surrounding explanation
- Length: As short as needed — no padding or summaries after the code
- Tone: Technical, precise — code speaks for itself
```
