---
name: chezmoi-sync
description: Sync dotfiles across machines via chezmoi and GitHub. Use when asked to sync, push, pull, or apply dotfiles on this machine or remote machines over SSH. Detects merge conflicts and reports them instead of auto-resolving.
---

# Chezmoi + GitHub dotfiles sync

Goal: configuration can be edited on any machine. Publish changes with chezmoi + git push; from a company machine, pull and apply them on the other company machines.

## Management scope

Keep this section aligned with `AGENTS.md` in the chezmoi source repository.

- Manage user-maintained configuration files under `~/.config`, subject to the selection, ignore, and safety rules in that file.
- Manage user-maintained Bash configuration files matching `~/.bash*` (for example, `.bashrc` and `.bash_aliases`), excluding history, secrets, and runtime state.
- Manage user-maintained Pi configuration under `~/.pi/agent` (respecting `PI_CODING_AGENT_DIR`), including settings, keybindings, global instructions, and user-authored resources. Exclude `auth.json`, sessions, caches, installed packages, and other runtime state; review `mcp.json` and `models.json` for secrets before managing them.
- On local desktop machines only (not SSH/headless machines), manage VS Code `~/.config/Code/User/settings.json` and `~/.config/Code/User/keybindings.json`.
- On macOS MacBooks, do not deploy ZTE-specific configuration or employee-identifying values. Keep general shell configuration managed; guard ZTE-only shell sections with chezmoi templates rather than ignoring entire shell files. Do not delete pre-existing local files just because they are excluded from chezmoi.
- When uncertain whether a file should be managed, leave it unmanaged and report the uncertainty rather than adding it automatically.

## Home Mac and other non-company machines

When `USER_TAG` is not `NewStarOS`, `187vm`, `187host`, or `18host`, a general chezmoi sync means syncing only this machine with GitHub. Review and publish intended local changes if any (section 1), then fetch, merge, review, and apply `origin/main` locally (section 2). A sync request authorizes the reviewed commit and push, but never authorizes SSH to the four company machines from here. Do not claim they are synchronized; changes pushed from here are distributed when a sync is later run on a company machine.

## Mandatory full sync on the four managed machines

These rules apply whenever `USER_TAG` is `NewStarOS`, `187vm`, `187host`, or `18host`. On these machines, a request to "chezmoi sync" (or an equivalent general sync request) means the complete workflow below, not just a pull/apply. **After every chezmoi change is pushed to GitHub from any of these machines, immediately perform the full synchronization on all four machines, even if the original request was only to commit and push. Never stop after `git push` or wait for a separate sync request.**

1. Inspect and review the current machine's local changes, then add them to chezmoi using section 1. Home/target changes that should win must be re-added; intentional source-tree edits must be preserved.
2. Commit only the intended changes in `~/.local/share/chezmoi` and push them to the GitHub chezmoi repository's `origin/main`. The sync request authorizes this commit and push. If there are no changes to publish, skip the commit and push.
3. After publishing, fetch, merge, and apply the latest `origin/main` on all four machines, including the machine that pushed:
   - `NewStarOS`
   - `187vm`
   - `187host`
   - `18host`
4. On each machine, after `chezmoi apply`, run `pi update --all` to update both Pi and all installed Pi packages.
5. Verify `chezmoi status --include=files` is clean on every machine. Finish only when all four machines use the same GitHub revision and managed configuration and the Pi update has completed successfully.

Run the update procedure on the current machine and the remote procedure on each of the other three machines. All safety rules below still apply, especially diff review, secret checks, and stopping for conflicts.

## Safety rules (always)

- **Never auto-resolve merge conflicts.** If `git merge` / `git pull` reports a conflict, STOP, notify the user, review the conflict, and show a suggested resolution.
- Review `chezmoi diff` before `chezmoi apply` or `chezmoi re-add`.
- Do not overwrite or delete local changes without reviewing their purpose.
- Never commit secrets.
- Keep changes minimal; do not add unrelated files.
- Do not commit or push for edit/review-only requests. An explicit sync request authorizes the commit and push described above.
- Preserve intentional host-specific configuration and report any uncommitted remote source edits.

## 1. Publish local changes (on the machine where config changed)

1. Inspect state: `chezmoi status --include=files` and `chezmoi diff --include=files`.
2. For already-managed files where the home/target version should win, run `chezmoi re-add <target>`. If re-add skips a template, make a minimal edit to the source template instead; preserve its directives and never replace it with rendered machine-specific output.
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
4. `chezmoi apply` (use `--force` only after reviewing the complete diff and understanding every change it will overwrite).
5. Update Pi and all installed Pi packages: `pi update --all`. Run this after `chezmoi apply` so the update uses the synced package declarations. If it fails, report the error and do not claim the full sync succeeded.
6. Verify `chezmoi status --include=files` is clean.

## 3. Update remote machines over SSH

For every other machine required by the four-machine sync (for example, `ssh 187vm`):

1. Test passwordless login first:
   ```bash
   ssh -o BatchMode=yes -o ConnectTimeout=8 <host> 'echo ok'
   ```
   If this fails, tell the user immediately and let them fix login. Do not try passwords.
2. After connecting, check the remote machine's network connectivity — first external connectivity (e.g. google.com), then GitHub:
   ```bash
   ssh <host> 'curl -sI --max-time 10 https://www.google.com -o /dev/null -w "google=%{http_code}\n"; curl -sI --max-time 10 https://github.com -o /dev/null -w "github=%{http_code}\n"'
   ```
   - If no push is needed, it is enough that the remote can pull (fetch) from origin.
   - When a proxy is needed, use port 1080: set `export PROXY_PORT=1080` in `~/.bashrc.local` (machine-specific, not managed by chezmoi) and git `http.proxy`/`https.proxy` to `http://127.0.0.1:1080`.
   - If there are SSH or network connection problems, report them to the user first, then execute subsequent operations.
3. Inspect the remote Git and chezmoi state before changing anything:
   ```bash
   ssh <host> 'cd ~/.local/share/chezmoi && git fetch origin && git status -sb && git log HEAD..origin/main --oneline'
   ssh <host> 'cd ~/.local/share/chezmoi && chezmoi status --include=files && chezmoi diff --include=files'
   ```
   If non-interactive SSH cannot find chezmoi, use `~/.local/bin/chezmoi` in remote commands.
4. If the remote tree is dirty or has local commits, report that merging may conflict before proceeding. Preserve the dirty source tree; never reset it to make the sync pass.
5. Merge on the remote: `ssh <host> 'cd ~/.local/share/chezmoi && git merge origin/main'`.
   If merge conflicts occur, STOP and report the host and conflicted files.
6. Review the post-merge `chezmoi diff`. Preserve reviewed target-only changes with `chezmoi re-add` or a minimal source edit before applying. On SSH/headless machines, ensure VS Code settings and keybindings are excluded.
7. Apply on the remote: `ssh <host> 'cd ~/.local/share/chezmoi && chezmoi apply'`. Use `--force` only under the same reviewed-diff rule as a local apply.
8. Update Pi and all installed Pi packages on the remote: `ssh <host> 'pi update --all'`. Report any failure and do not claim the full sync succeeded.
9. Verify the remote revision and chezmoi state:
   ```bash
   ssh <host> 'cd ~/.local/share/chezmoi && git rev-parse HEAD origin/main && chezmoi status --include=files'
   ```

## Conflict notification format

When a conflict is detected, report:
- host name (or "local")
- conflicted file paths
- whether local changes would be overwritten
- a review of the conflict and a suggested resolution

Then wait for the user to decide how to resolve.
