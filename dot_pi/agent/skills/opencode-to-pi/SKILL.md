---
name: opencode-to-pi
description: Migrate OpenCode sessions into resumable Pi sessions using OpenCode's official JSON export and smigrate import. Use when asked to export, convert, import, or migrate an OpenCode conversation/session to Pi, especially when smigrate transfer rejects the installed OpenCode version.
compatibility: Requires the opencode, smigrate (session-migrate), and pi CLIs.
---

# Migrate an OpenCode session to Pi

Convert the conversation through OpenCode's official session export, then let `smigrate import` create the Pi session. This avoids OpenCode database edits and works when `smigrate transfer` rejects a newer OpenCode CLI.

## Safety

- Never modify or delete the source OpenCode session or its database.
- Select the source by exact session ID, not only by title.
- Run the import dry-run before installing the target session.
- Session exports contain prompts, command output, and possibly secrets. Use private temporary files and remove them after validation.
- Do not use `opencode session export --sanitize` for a full-fidelity migration unless the user requests redaction.
- Report conversion warnings and dropped event kinds; do not claim metadata or reasoning was preserved when the converter dropped it.

## 1. Identify the session and versions

Run `opencode session list` from the source project directory. If the user supplied a title, use the list to resolve it to one exact `ses_...` ID; ask if the title is ambiguous.

Record the versions before migrating:

```bash
opencode --version
smigrate --version
pi --version
```

OpenCode 2.1.4 is recognized by `smigrate inspect` and `smigrate import`, although `smigrate transfer` 0.12.0 rejects it because that command's source-CLI guard only accepts 1.17.20 or supported 2.0.x versions. Do not downgrade OpenCode or edit its database; use the export/import workflow below.

## 2. Export and inspect the source

Set these values for the requested migration, using the source project's absolute path:

```bash
SOURCE_ID='ses_...'
PROJECT_CWD='/absolute/path/to/project'
PI_HOME="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
```

Preserve these values across shell invocations, or run the workflow in one shell. Create a private export and inspect it:

```bash
umask 077
EXPORT="$(mktemp /tmp/opencode-to-pi-XXXXXXXX.json)"
(
  cd "$PROJECT_CWD"
  opencode session export "$SOURCE_ID" > "$EXPORT"
)
smigrate inspect "$EXPORT" --format opencode --json
```

Confirm that inspection identifies `format: opencode`, the expected source session ID, and the expected project cwd. Stop if the export is empty, invalid, or belongs to another session.

## 3. Dry-run the Pi import

```bash
smigrate import "$EXPORT" \
  --format opencode \
  --to pi \
  --home "$PI_HOME" \
  --cwd "$PROJECT_CWD" \
  --target-cli-version "$(pi --version)" \
  --dry-run
```

Review the proposed output path, collision checks, dropped events, and warnings. A dry-run may create a migration manifest, but must not install the target session.

An `unvalidated_target_version` warning means the target version differs from the converter's validated metadata version; it is not by itself a failed migration. Continue only with the post-import Pi validation below.

## 4. Import into Pi

If the dry-run succeeds and its warnings are acceptable, rerun without `--dry-run`:

```bash
smigrate import "$EXPORT" \
  --format opencode \
  --to pi \
  --home "$PI_HOME" \
  --cwd "$PROJECT_CWD" \
  --target-cli-version "$(pi --version)"
```

Capture `session_id` and `output` from the JSON result. Store the output path as `TARGET_FILE` for validation:

```bash
TARGET_FILE='/path/from/import/output.jsonl'
```

Do not invent the target path or reuse the dry-run session ID: a real import generates a new ID.

## 5. Validate and clean up

Validate both the converted structure and Pi's ability to load/export it:

```bash
smigrate inspect "$TARGET_FILE" --format pi --json
VALIDATION_HTML="${EXPORT%.json}.validation.html"
pi --export "$TARGET_FILE" "$VALIDATION_HTML"
```

Confirm that:
- the target cwd and session name are correct;
- the Pi header uses a supported session schema;
- expected user/assistant messages and tool calls/results are present; and
- `pi --export` exits successfully.

Remove temporary transcript-derived files after successful validation:

```bash
rm -f -- "$EXPORT" "$VALIDATION_HTML"
```

Report the source ID, target Pi session ID and file, validation result, and any dropped events or warnings. Give the user the exact resume command:

```bash
pi --session <target-session-id>
```

If inspection or Pi validation fails, report the failure and preserve the temporary export for diagnosis only if the user agrees; never claim the migration succeeded.
