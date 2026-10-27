# OpenCode Language Tutor (V2)

Writing feedback while you code: prompts you write in the language you are
learning are reviewed in the background, and corrections appear above the
prompt in your native language. Inspired by
[pi-language-tutor](https://github.com/mackt/pi-language-tutor) and its
[OpenCode V1 port](https://github.com/kjasn/opencode-language-tutor).

**Current scope: writing check only.** Translation cards, the writing tutor,
and flashcards are intentionally not included yet.

## Preview

After you send a prompt, the strip above the composer shows up to three fixes
plus one more natural phrasing:

```text
  ─────────────────────────────────────────────────────────────

   ✏ Writing check
   “i” → “I”  第一人称代词 I 必须大写。
   “wants” → “want”  主语 I 后动词用原形。
   “what is the tech stack of this project” → “what the tech stack of this project
   is”  know 后的宾语从句用陈述语序。
   ◇ I'd like to know what tech stack this project uses.
  ┃
  ┃  Build · DeepSeek V4.1 Flash 1017 · max
```

`/writing` opens the same review in a persistent, scrollable panel with the
reasons on separate lines. `/lang-tu` opens settings.

## Why V2 makes this practical

The V1 port had to work around several missing APIs. V2 provides them
directly, so this implementation is a single TUI plugin:

| Need | V1 workaround | V2 API used here |
| --- | --- | --- |
| Run an LLM call without touching the conversation | create a temporary session, custom agent with tools disabled, delete it | `client.generate.text` — no session, no tools, no history |
| Persist results between the server plugin and TUI | JSON file bridge under `~/.local/state` | `context.storage.store` (durable, reactive) |
| Show feedback next to the prompt | replace/recompose the stock prompt slot | `session.composer.top` slot |
| Show a long, persistent review | toast notification + `/translations` dialog | `session.panel` slot |
| React to a submitted prompt | server `chat.message` hook | `session.inbox.enqueued` event |

No server plugin, no temporary sessions, no agent config, and no file bridge
are needed.

### What still does not disappear

V2's slot map has no message-level renderer. A plugin cannot inject a
translation or a correction *under an individual historical message* in the
transcript. This implementation uses the two closest supported surfaces:
the composer-top strip and a host-managed side panel. That is a deliberate
design constraint, not a missing feature in this plugin.

## Install

The plugin is a local CLI plugin. For a personal setup, copy it into the
global OpenCode config directory:

```sh
cp -R opencode-language-tutor ~/.config/opencode/language-tutor
```

Then add it to `~/.config/opencode/cli.json`:

```json
{
  "plugins": ["./bell", "./language-tutor"]
}
```

OpenCode reloads `cli.json` without a restart. If it does not, run
`/reload` in the TUI.

To remove it, delete the `./language-tutor` entry and the
`~/.config/opencode/language-tutor` directory.

## Usage

| Command | What it does |
| --- | --- |
| `/lang-tu` | Learning language, native language, writing check on/off, model |
| `/writing` | Open the full review panel |

Defaults are English (`en`) for learning and Simplified Chinese (`zh-CN`) for
native explanations. The check runs automatically for prompts that pass the
heuristics; slash commands, code fences, very short messages, and
identifier-heavy text are skipped.

Writing checks use the session model by default. Choose a cheaper model in
`/lang-tu` if you want to control cost.

## Not implemented yet

This pass is intentionally limited to the writing check:

- no translation of assistant replies
- no writing tutor for native-language prompts
- no flashcards or spaced repetition
- no context-aware review (the check sees only the prompt text)

The composer strip and the full panel are the two rendering surfaces. V2 has no
message-level renderer, so the check cannot be attached to an individual
historical message in the transcript.

## Architecture

```text
tui.tsx                root re-export so local plugin discovery finds the entry
src/tui.tsx            plugin shell: storage, events, slots, commands, dialogs
src/core.ts            pure logic: settings, prompt, parsing, skip heuristics
test/core.test.ts      unit tests for the pure layer
```

The TUI subscribes to `session.inbox.enqueued`, filters the prompt, and calls
`client.generate.text` with a JSON-only review prompt. The result is stored in
`context.storage` under the session ID; the strip and panel read the same
reactive store, so both update when the check finishes. A new prompt aborts
any in-flight review for that session.

## Development

```sh
bun install
bun run typecheck
bun test
bun run build
```

## Attribution

The behavior and prompt heuristics are inspired by
[pi-language-tutor](https://github.com/mackt/pi-language-tutor) (MIT) and
[opencode-language-tutor](https://github.com/kjasn/opencode-language-tutor)
(MIT). This V2 implementation is new code built against the OpenCode V2
plugin API.
