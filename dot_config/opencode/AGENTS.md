# Global instructions

## Search tools

- ALWAYS use the shell tool with `rg` (ripgrep) for content searches and `fd` for file searches.
- Do NOT use the dedicated `grep` tool for content searches or the `glob` tool for finding files — use shell `rg` / `fd` instead, even when the dedicated tool could do the job.
- Useful defaults: `rg --hidden --glob '!.git'` for hidden files; `fd --hidden --exclude .git` likewise.
