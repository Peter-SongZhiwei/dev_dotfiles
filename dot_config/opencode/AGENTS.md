# Global instructions

## Search tools

- ALWAYS use the shell tool with `rg` (ripgrep) for content searches and `fd` for file searches.
- Do NOT use the dedicated `grep` tool for content searches or the `glob` tool for finding files — use shell `rg` / `fd` instead, even when the dedicated tool could do the job.
- Useful defaults: `rg --hidden --glob '!.git'` for hidden files; `fd --hidden --exclude .git` likewise.

## Chezmoi dotfiles management

Goal: maintain a clean, portable, minimal, and reproducible dotfiles repository using chezmoi. Prefer correctness and maintainability over tracking every configuration file.

Management scope:
- Manage user-maintained configuration files under `~/.config`, subject to the selection, ignore, and safety rules below.
- Manage user-maintained Bash configuration files matching `~/.bash*` (for example, `.bashrc` and `.bash_aliases`), excluding history, secrets, and runtime state.
- On local desktop (non-SSH/headless) machines only, manage VS Code `~/.config/Code/User/settings.json` and `~/.config/Code/User/keybindings.json`.

1. File selection
   - Manage only user-maintained configuration files useful for reproducing the dev environment.
   - Ignore empty dirs/files (unless required), temporary files, caches, logs, backups, swap files, generated artifacts, runtime/session state, lock files, and machine-specific data.
   - Do not recursively add an entire application directory without inspecting its contents.
   - Preserve the original configuration structure whenever possible.
2. Sensitive information
   - Never commit plaintext passwords, tokens, API keys, private keys, or other secrets.
   - Prefer environment variables, secret managers, or chezmoi encryption. Inspect files for secrets before adding/committing.
3. Synchronization
   - Treat chezmoi's source state as canonical. Inspect differences before syncing.
   - Preserve existing templates, conditional config, and file attributes; do not replace templates with rendered machine-specific values.
   - Do not overwrite/delete local changes without reviewing their purpose. Avoid adding unrelated files.
   - Do not automatically commit or push unless explicitly requested.
4. Portability
   - Prefer config that works across machines; avoid hardcoded home dirs, usernames, absolute paths, device-specific settings.
   - Use chezmoi templates only for meaningful OS/host differences.
5. Minimal changes
   - Make the smallest changes necessary; preserve formatting, comments, ordering unless modification is required.
   - Remove obsolete managed entries only after verifying they are no longer needed.
6. Safety
   - Never use destructive sync options without explicit approval; no `exact_` dirs without understanding deletion behavior.
   - Review impact before `chezmoi apply`; do not run unfamiliar scripts; never delete unmanaged local files merely because absent from the repo.
7. Verification — after modifying managed config: check the repo diff, validate source state, preview `chezmoi apply`, check for unintended additions/deletions/secrets, and report changed files and risks.
8. Remote (SSH) machines
   - Over SSH (headless, no GUI), sync with `chezmoi apply` and adopt local tweaks with `chezmoi add` as usual.
   - Do NOT manage VS Code `settings.json` or `keybindings.json` on SSH/headless machines — they are desktop (GUI) configs.
   - Keep SSH-side changes minimal and terminal-focused (shell, tmux, nvim, git).

When uncertain whether a file should be managed, leave it unmanaged and report the uncertainty rather than adding it automatically.
