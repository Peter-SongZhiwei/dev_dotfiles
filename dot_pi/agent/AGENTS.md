# Code style

- Use clear names and self-explanatory code.
- Write comments that explain what the code cannot.
- Extract small functions when they improve clarity.

# Chezmoi sync

- When `USER_TAG` is not `NewStarOS`, `187vm`, `187host`, or `18host`, a general sync request means review and publish intended local changes to GitHub if any, then fetch, merge, and apply `origin/main` on this machine only. Do not SSH to the four company machines or claim they are synchronized; changes pushed from here are distributed by a later sync on a company machine.
- These rules apply whenever `USER_TAG` is `NewStarOS`, `187vm`, `187host`, or `18host`. A request to sync chezmoi means the full publish-and-distribute workflow:
  1. Review the current machine's local configuration changes and add them to chezmoi. Use `chezmoi re-add` when the home/target version should win; preserve intentional edits made directly in the chezmoi source tree.
  2. Commit only the intended changes in `~/.local/share/chezmoi` and push the repository to its GitHub `origin/main`.
  3. Synchronize and apply the result on all four machines: `NewStarOS`, `187vm`, `187host`, and `18host`.
  4. Verify chezmoi is clean on every machine.
- **After every chezmoi change is pushed to GitHub from any of these four machines, immediately synchronize all four machines, even if the original request was only to commit and push. Do not stop after `git push` or wait for a separate sync request.**
- On every machine, including the one that pushed, fetch and merge the latest `origin/main`, run `chezmoi apply`, and verify chezmoi is clean. Finish only when all four machines use the same GitHub revision and managed configuration.
- If there are no local changes to publish, skip the commit and push and continue with synchronization.
- Follow the `chezmoi-sync` skill's safety rules: review diffs, never commit secrets, and never auto-resolve merge conflicts.
