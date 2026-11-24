---
name: opencode-to-pi
description: Migrate OpenCode sessions into resumable Pi sessions using OpenCode's official JSON export and smigrate import. Use when asked to export, convert, import, or migrate an OpenCode conversation/session to Pi, especially when smigrate transfer rejects the installed OpenCode version or smigrate is not installed yet.
compatibility: Requires the opencode and pi CLIs; smigrate (PyPI package session-migrate) is installed on demand via uv.
---

# Migrate an OpenCode session to Pi

Convert the conversation through OpenCode's official session export, then let `smigrate import` create the Pi session. This avoids OpenCode database edits and works when `smigrate transfer` rejects a newer OpenCode CLI.

Verified working combination (2026-11): `opencode 2.2.7` → `session-migrate 0.12.0` (`smigrate`) → `pi 1.5.2`.

## Safety

- Never modify or delete the source OpenCode session or its database.
- Select the source by exact session ID, not only by title.
- Run the import dry-run before installing the target session.
- Session exports contain prompts, command output, and possibly secrets. Use private temporary files and remove them after validation.
- Do not use `opencode session export --sanitize` for a full-fidelity migration unless the user requests redaction.
- Report conversion warnings and dropped event kinds; do not claim metadata or reasoning was preserved when the converter dropped it.
- Only delete Pi session files that this workflow just created. Never delete sessions that already existed.

## 1. Prepare the tools and record versions

`smigrate` is the shorthand for the PyPI package `session-migrate`; it is frequently not installed yet.

```bash
command -v smigrate || uv tool install session-migrate
export PATH="$HOME/.local/bin:$PATH"   # uv tool installs here

opencode --version
smigrate --version
pi --version
```

`smigrate transfer` 0.12.0 rejects OpenCode 2.x (its source-CLI guard only accepts 1.17.20 and supported 2.0.x), but `smigrate inspect` and `smigrate import` still parse 2.x exports. Do not downgrade OpenCode and do not edit its database; use the export/import workflow below.

## 2. Identify the sessions

Run `opencode session list` from the source project directory (the session, not the target, decides this directory). It prints `ses_...`, title, and date.

If the user named a project directory rather than a session, treat "the session history" as *all* substantive sessions there:

```bash
cd "$SOURCE_PROJECT_CWD"
opencode session list
```

Size them before committing to a long migration — a title alone is misleading (a session titled `Greeting` can contain real work):

```bash
umask 077
mkdir -p /tmp/oc2pi
for s in ses_... ses_...; do
  opencode session export "$s" > "/tmp/oc2pi/$s.json"
  printf '%s %8s bytes msgs=%s\n' "$s" "$(stat -c%s "/tmp/oc2pi/$s.json")" \
    "$(python3 -c "import json;print(len(json.load(open('/tmp/oc2pi/$s.json'))['messages']))")"
done
```

Migrate the substantive sessions (`msgs` in the tens or hundreds). Ask before importing near-empty sessions (a handful of `Untitled`/`Greeting` stubs with 3–13 messages).

## 3. Export and inspect each source

```bash
SOURCE_ID='ses_...'
SOURCE_PROJECT_CWD='/absolute/path/where_the_opencode_session_lives'
TARGET_CWD='/absolute/path/of_the_pi_project'      # often different, see step 4
PI_HOME="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
EXPORT="/tmp/oc2pi/$SOURCE_ID.json"
```

```bash
smigrate inspect "$EXPORT" --format opencode --json
```

Confirm `format: opencode`, the expected `session_id`, cwd equal to `SOURCE_PROJECT_CWD`, and non-zero `tool_calls`/`tool_results`. Stop if the export is empty, invalid, or belongs to another session.

## 4. Dry-run the Pi import

`--cwd` is the **target** project, and it controls both the Pi session's recorded cwd and its storage directory `$PI_HOME/sessions/--<cwd with / and . replaced by ->--/`. To land a session in another repo, export from the source project but import with the target cwd:

```bash
smigrate import "$EXPORT" \
  --format opencode \
  --to pi \
  --home "$PI_HOME" \
  --cwd "$TARGET_CWD" \
  --target-cli-version "$(pi --version)" \
  --dry-run
```

Review the proposed `output` path, collision checks, and `warnings`. A dry-run writes a manifest under `$PI_HOME/session-migrate/manifests/` but must not install the target session.

Expected warnings (not failures):

- `unvalidated_target_version` — the converter's pinned metadata version (e.g. `0.80.6`) differs from the installed Pi (e.g. `1.5.2`). The writer schema stays at Pi `schema_v3`; step 6 is what actually proves compatibility.
- `dropped_event_kind` — OpenCode-only detail the Pi writer cannot store. Typical counts for a long 2.x session: `thinking`, `opaque:opencode_tool_metadata`, `opencode_v2_message_model_variant`, `opencode_v2_idle_record`, `opencode_v2_model-switched_record`, `opencode_v2_system_record`, `opencode_v2_error`, `opencode_v2_unknown_assistant_content_fields`.

If the dry-run points at an unexpected cwd/session directory, stop and fix `--cwd` before importing.

## 5. Import into Pi

Rerun without `--dry-run`, one invocation per session:

```bash
smigrate import "$EXPORT" \
  --format opencode \
  --to pi \
  --home "$PI_HOME" \
  --cwd "$TARGET_CWD" \
  --target-cli-version "$(pi --version)"
```

Capture `session_id` and `output`:

```bash
TARGET_FILE='/path/from/import/output.jsonl'
```

Do not reuse the dry-run session ID: a real import generates a new one.

## 6. Validate and clean up

```bash
smigrate inspect "$TARGET_FILE" --format pi --json
pi --export "$TARGET_FILE" "/tmp/oc2pi/$(basename "$TARGET_FILE" .jsonl).html"
```

Confirm that:

- `format: pi`, `cwd` equals `TARGET_CWD`, and the session header reports `schema_v3`;
- user/assistant/toolResult counts and `tool_calls` == `tool_results` are non-zero and plausible against the source inspection;
- `pi --export` exits 0 (this is the real load test — it parses the whole session).

Tool-name fidelity: the converter keeps OpenCode tool names (`shell`, `edit`, `read`, `write`, `grep`, `glob`, `question`), so history renders with them and Pi resumes the session normally; only new calls use Pi's own tools. Check what actually landed:

```bash
python3 - "$TARGET_FILE" <<'EOF'
import collections, json, sys
names = collections.Counter()
for line in open(sys.argv[1]):
    message = json.loads(line).get('message')
    content = message.get('content') if isinstance(message, dict) else None
    for block in content if isinstance(content, list) else []:
        if isinstance(block, dict):
            names[block.get('name') or 'block:' + str(block.get('type'))] += 1
print(names.most_common())
EOF
```

Remove temporary transcript-derived files after successful validation:

```bash
rm -f -- "/tmp/oc2pi/$SOURCE_ID.json" "/tmp/oc2pi/$(basename "$TARGET_FILE" .jsonl).html"
```

If an earlier attempt imported to the wrong `--cwd`, re-import with the correct one, then delete only the stale copies created by that attempt (verify their timestamps/content cwd first). If the abandoned directory is left empty, remove it too.

## 7. Report

Give the user, per session: source `ses_...` ID and title, target Pi session ID and file path, target cwd, record/tool-call counts, validation result, and the dropped event kinds with counts. Then the exact resume command — run from the target project so `pi` resolves the session directory:

```bash
cd "$TARGET_CWD"
pi --session <target-session-id>
```

Also state explicitly which sessions were *not* migrated (near-empty stubs) and offer to import them.

If inspection or Pi validation fails, report the failure and preserve the temporary export for diagnosis only if the user agrees; never claim the migration succeeded.
