---
name: chezmoi-sync
description: Sync dotfiles across machines via chezmoi and GitHub. Use when asked to sync, push, pull, or apply dotfiles on this machine or remote machines over SSH. Detects merge conflicts and reports them instead of auto-resolving.
---

# Chezmoi + GitHub dotfiles sync

Goal: configuration can be edited on any machine. Publish changes with chezmoi + git push, then pull and apply on other machines.

## 0. Determine scope and run the mandatory version check

Before any `chezmoi re-add`/`chezmoi add`, Git fetch/merge/pull/push, `chezmoi apply`, or Pi update, classify the local machine:

- **ZTE scope:** `USER_TAG` is non-empty. Inventory the local machine and all other ZTE machines over SSH.
- **Standalone Mac scope:** the OS is macOS and `USER_TAG` is empty or unset. Inventory only the Mac itself.
- Never attempt SSH between the ZTE group and the standalone Mac, including for version checks or unreachable-machine placeholders.

Run:

```bash
bash ~/.config/chezmoi-sync/versions.sh --all
```

If the applied script is not available yet, run the source copy instead:

```bash
bash ~/.local/share/chezmoi/dot_config/chezmoi-sync/executable_versions.sh --all
```

The script always reports the local machine. In ZTE scope it uses passwordless SSH for the other entries in `ZTE_MACHINES`; it sends itself over SSH so the check works before remotes receive the script. In Mac scope it performs no SSH operations.

Reports are scope-owned and chezmoi-managed:

- ZTE: `~/.config/chezmoi-sync/software-versions-zte.md`
- Mac: `~/.config/chezmoi-sync/software-versions-mac.md`

Review the scope's report, its path, and any version-query failures before continuing. Each sync updates only its own scope's report, preventing Mac and ZTE jobs from overwriting each other. Use `chezmoi add` the first time a report is created and `chezmoi re-add` thereafter, then commit and distribute it with the intended configuration changes. Do not hand-edit generated reports or upgrade tools merely to make versions uniform.

## Synchronization topology

- The ZTE machines synchronize directly with each other through GitHub plus SSH. A sync or chezmoi push from any ZTE machine requires the full ZTE workflow below.
- The standalone Mac synchronizes only with GitHub and itself. A Mac sync never runs the remote-ZTE procedure, and a Mac push does not trigger immediate ZTE synchronization.
- A ZTE push does not trigger immediate Mac synchronization. Shared changes propagate asynchronously: Mac changes arrive at ZTE machines on their next sync, and ZTE changes arrive at the Mac on its next sync.
- GitHub is the only connection between the two groups. Do not add the Mac to `ZTE_MACHINES` or attempt reverse SSH from the Mac.

## Management scope

Keep this section aligned with `AGENTS.md` in the chezmoi source repository.

- Manage user-maintained configuration files under `~/.config`, subject to the selection, ignore, and safety rules in that file.
- Manage user-maintained Bash configuration files matching `~/.bash*` (for example, `.bashrc` and `.bash_aliases`), excluding history, secrets, and runtime state.
- Manage user-maintained Pi configuration under `~/.pi/agent` (respecting `PI_CODING_AGENT_DIR`), including settings, keybindings, global instructions, and user-authored resources. Exclude `auth.json`, sessions, caches, installed packages, and other runtime state; review `mcp.json` and `models.json` for secrets before managing them.
- On local desktop machines only (not SSH/headless machines), manage VS Code `~/.config/Code/User/settings.json` and `~/.config/Code/User/keybindings.json`.
- On macOS MacBooks, do not deploy ZTE-specific configuration or employee-identifying values. Keep general shell configuration managed; guard ZTE-only shell sections with chezmoi templates rather than ignoring entire shell files. Do not delete pre-existing local files just because they are excluded from chezmoi.
- When uncertain whether a file should be managed, leave it unmanaged and report the uncertainty rather than adding it automatically.

## Mandatory full sync on ZTE machines

These rules apply whenever `USER_TAG` is non-empty. A request to "chezmoi sync" (or an equivalent general sync request) means the complete workflow below, not just a pull/apply. The current ZTE inventory is `NewStarOS`, `187vm`, `187host`, `18host`, and `18vm`; `NewStartOS` is normalized to the report label `NewStarOS`. **After every chezmoi change is pushed to GitHub from any ZTE machine, immediately perform the full synchronization on all five ZTE machines, even if the original request was only to commit and push. Never stop after `git push` or wait for a separate sync request.**

1. Complete the all-machine software version check in section 0 and review its Markdown report.
2. Inspect and review the current machine's local changes, then add them to chezmoi using section 1. Home/target changes that should win must be re-added; intentional source-tree edits must be preserved.
3. Commit only the intended changes in `~/.local/share/chezmoi` and push them to the GitHub chezmoi repository's `origin/main`. The sync request authorizes this commit and push. If there are no changes to publish, skip the commit and push.
4. After publishing, fetch, merge, and apply the latest `origin/main` on all five machines, including the machine that pushed:
   - `NewStarOS`
   - `187vm`
   - `187host`
   - `18host`
   - `18vm`
5. On each machine, after `chezmoi apply`, run `pi update --all` to update both Pi and all installed Pi packages.
6. Verify `chezmoi status --include=files` is clean on every machine. Finish only when all five machines use the same GitHub revision and managed configuration and the Pi update has completed successfully.

Run the update procedure on the current ZTE machine and the remote procedure on each of the other four ZTE machines. All safety rules below still apply, especially diff review, secret checks, and stopping for conflicts.

## Standalone Mac GitHub-only sync

On macOS without `USER_TAG`, a sync request means only this workflow:

1. Complete the local-only version check in section 0 and add/re-add `software-versions-mac.md`.
2. Review and publish intended local changes using section 1.
3. Fetch, merge, apply, update Pi, and verify locally using section 2.
4. Finish when the local GitHub revision and chezmoi state are clean. Do not run section 3 and do not wait for or initiate ZTE synchronization.

Preserve all macOS ignore/template rules. The OS-based guards exclude ZTE-specific configuration without deleting pre-existing local Mac files.

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

For every other ZTE machine required by the five-machine sync (for example, `ssh 187vm`). Never run this procedure for the standalone Mac:

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
