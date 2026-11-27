# Code style

- Use clear names and self-explanatory code.
- Write comments that explain what the code cannot.
- Extract small functions when they improve clarity.

# Chezmoi sync

- Classify synchronization scope before every operation:
  - A non-empty `USER_TAG` means **ZTE scope**. The current inventory is `NewStarOS`, `187vm`, `187host`, and `18host`; normalize `NewStartOS` to `NewStarOS` for reporting. `18vm` was retired on 2026-11-27 and is out of scope.
  - macOS with `USER_TAG` empty or unset means **standalone Mac scope**.
- Never attempt SSH between the ZTE group and the standalone Mac. GitHub is the only connection between the groups. Configuration changes propagate asynchronously the next time the other group syncs.
- Before either sync workflow, run the scope-aware version check. ZTE checks all four ZTE machines and manages `software-versions-zte.md`; the Mac checks only itself and manages `software-versions-mac.md`. Each scope updates only its own report.
- A request to sync chezmoi on a ZTE machine means the full publish-and-distribute workflow:
  1. Review the current machine's local configuration changes and add them to chezmoi. Use `chezmoi re-add` when the home/target version should win; preserve intentional edits made directly in the chezmoi source tree.
  2. Commit only the intended changes in `~/.local/share/chezmoi` and push the repository to its GitHub `origin/main`.
  3. Synchronize and apply the result on all four ZTE machines: `NewStarOS`, `187vm`, `187host`, and `18host`.
  4. Run `pi update --all` and verify chezmoi is clean on every ZTE machine.
- **After every chezmoi change is pushed to GitHub from any ZTE machine, immediately synchronize all four ZTE machines, even if the original request was only to commit and push. Do not stop after `git push` or wait for a separate sync request.**
- On every ZTE machine, including the one that pushed, fetch and merge the latest `origin/main`, run `chezmoi apply`, and verify chezmoi is clean. Finish only when all four ZTE machines use the same GitHub revision and managed configuration.
- A request to sync chezmoi on the standalone Mac means only the local/GitHub workflow: run the local version check, publish intended changes when requested, fetch and merge `origin/main`, apply locally, update Pi, and verify local chezmoi cleanliness. Never run the ZTE remote procedure.
- A Mac push does not trigger immediate ZTE synchronization, and a ZTE push does not trigger immediate Mac synchronization.
- If there are no local changes to publish, skip the commit and push and continue with the applicable scope's synchronization.
- Follow the `chezmoi-sync` skill's safety rules: review diffs, never commit secrets, and never auto-resolve merge conflicts.
