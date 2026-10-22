Chezmoi Management Guidelines

Goal

Maintain a clean, portable, minimal, and reproducible dotfiles repository using chezmoi.

Prefer correctness and maintainability over tracking every configuration file.

1. File Selection

* Manage only user-maintained configuration files that are useful for reproducing the development environment.
* Ignore empty directories unless their existence is explicitly required by an application.
* Ignore empty files unless they have a meaningful purpose.
* Ignore temporary files, caches, logs, backups, swap files, and generated artifacts.
* Ignore application runtime state, session state, lock files, and machine-specific data.
* Do not recursively add an entire application directory without inspecting its contents.
* Preserve the original configuration structure whenever possible.

2. Sensitive Information

* Never commit plaintext passwords, access tokens, API keys, private keys, or other secrets.
* Prefer environment variables, secret managers, or chezmoi encryption for sensitive configuration.
* Inspect files for secrets before adding or committing them.
* Treat SSH private keys and authentication credentials as sensitive by default.

3. Synchronization

* Treat chezmoi’s source state as the canonical repository of managed configuration.
* Before synchronization, inspect differences between the current system and chezmoi’s source state.
* Preserve existing templates, conditional configuration, and file attributes.
* Do not replace templates with rendered machine-specific values.
* Do not overwrite or delete local changes without reviewing their purpose.
* Avoid adding unrelated files during synchronization.
* Do not automatically commit or push changes unless explicitly requested.

4. Portability

* Prefer configuration that works across multiple machines.
* Avoid hardcoded home directories, usernames, absolute paths, and device-specific settings.
* Use chezmoi templates for meaningful OS-specific or host-specific differences.
* Do not introduce templates for configurations that do not require them.

5. Minimal Changes

* Make the smallest changes necessary.
* Preserve existing formatting, comments, and ordering unless modification is required.
* Avoid unnecessary file renaming or directory restructuring.
* Avoid introducing placeholder files solely to preserve empty directories.
* Remove obsolete managed entries only after verifying they are no longer needed.

6. Safety

* Never use destructive synchronization options without explicit approval.
* Do not introduce exact_ directories without understanding their deletion behavior.
* Review the impact of changes before running chezmoi apply.
* Do not execute unfamiliar scripts contained in the repository without inspecting them.
* Never delete unmanaged local files merely because they are absent from the repository.

7. Verification

After modifying managed configuration:

1. Check the repository diff.
2. Validate chezmoi’s source state.
3. Preview the changes that chezmoi apply would make.
4. Check for unintended additions, deletions, and secrets.
5. Report changed files and any potential risks.

8. Remote (SSH) Machines

* When connected over SSH (headless, no GUI), sync with `chezmoi apply` and adopt local tweaks with `chezmoi add` as usual.
* Do NOT manage VS Code `settings.json` or `keybindings.json` on SSH/headless machines — they are desktop (GUI) configs and do not apply there.
* Keep SSH-side changes minimal and terminal-focused (shell, tmux, nvim, git).

General Principle

When uncertain whether a file should be managed, leave it unmanaged and report the uncertainty rather than adding it automatically.
