---
name: chezmoi-sync
description: Sync dotfiles across machines via chezmoi and GitHub. Use when asked to sync, push, pull, or apply dotfiles on this machine or remote machines over SSH. Detects merge conflicts and reports them instead of auto-resolving.
---

# Chezmoi + GitHub dotfiles sync

Goal: configuration can be edited on any machine. Publish changes with chezmoi + git push, then pull and apply on other machines.

## Safety rules (always)

- **Never auto-resolve merge conflicts.** If `git merge` / `git pull` reports a conflict, STOP, notify the user, review the conflict, and show a suggested resolution.
- Review `chezmoi diff` before `chezmoi apply` or `chezmoi re-add`.
- Do not overwrite or delete local changes without reviewing their purpose.
- Never commit secrets.
- Keep changes minimal; do not add unrelated files.
- Do not commit or push unless the user asked for it.

## 1. Publish local changes (on the machine where config changed)

1. Inspect state: `chezmoi status --include=files` and `chezmoi diff --include=files`.
2. For files where the home/target version should win, run `chezmoi re-add <target>`.
3. For files edited directly in the chezmoi source tree, keep the source version.
4. Stage only the intended files: `git add <paths>`.
5. Commit with a short, specific message.
6. `git push`.
   - If rejected, `git fetch origin` and inspect `git log HEAD..origin/main`.
   - Merge if safe; if any conflict appears, STOP and notify the user.

## 2. Update this machine from GitHub

1. `cd ~/.local/share/chezmoi && git fetch origin`.
2. Check `git status -sb` and `git log HEAD..origin/main --oneline`.
3. `git merge origin/main` (this repo uses merge commits).
   - If conflict: STOP, list conflicted files, and notify the user.
4. `chezmoi apply` (use `--force` only when the change is understood).
5. Verify `chezmoi status --include=files` is clean.

## 3. Update remote machines over SSH

For each host the user names (e.g. `ssh 187vm`):

1. Test passwordless login first:
   ```bash
   ssh -o BatchMode=yes -o ConnectTimeout=8 <host> 'echo ok'
   ```
   If this fails, tell the user immediately and let them fix login. Do not try passwords.
2. After connecting, confirm the remote machine's network connectivity (e.g. whether it can reach GitHub/origin, and whether a proxy is required):
   ```bash
   ssh <host> 'curl -sI --max-time 10 https://github.com -o /dev/null -w "%{http_code}\n"'
   ```
   If there are SSH or network connection problems, report them to the user first, then execute subsequent operations.
3. Inspect the remote state before changing anything:
   ```bash
   ssh <host> 'cd ~/.local/share/chezmoi && git fetch origin && git status -sb && git log HEAD..origin/main --oneline'
   ```
4. If the remote tree is dirty or has local commits, report that merging may conflict before proceeding.
5. Merge and apply on the remote:
   ```bash
   ssh <host> 'cd ~/.local/share/chezmoi && git merge origin/main && chezmoi apply'
   ```
   If merge conflicts occur, STOP and report the host and conflicted files.
6. Verify on the remote: `ssh <host> 'cd ~/.local/share/chezmoi && chezmoi status --include=files'`.

## Conflict notification format

When a conflict is detected, report:
- host name (or "local")
- conflicted file paths
- whether local changes would be overwritten
- a review of the conflict and a suggested resolution

Then wait for the user to decide how to resolve.

## Scope reminders

- Manage `~/.config` and `~/.bash*` per AGENTS.md.
- On SSH/headless machines, do NOT manage VS Code `settings.json` or `keybindings.json`.
