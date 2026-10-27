/**
 * OpenCode V2 CLI plugin: writing feedback beside the prompt.
 *
 * The TUI process does all the work:
 * - `client.generate.text` runs the review without creating a session, so
 *   nothing is added to the conversation and no context is spent.
 * - `context.storage` keeps settings and per-session results across restarts.
 * - `session.composer.top` renders the compact feedback strip.
 * - `session.panel` renders the persistent full review.
 */

import { Plugin } from "@opencode/plugin/tui"
import type { Context, PanelInput } from "@opencode/plugin/tui/context"
import { For, Match, Show, Switch } from "solid-js"
import type { JSX } from "solid-js"
import type { Store } from "solid-js/store"
import {
  DEFAULT_SETTINGS,
  LANGUAGES,
  type ModelChoice,
  type ReviewResult,
  type Settings,
  type WritingItem,
  buildReviewPrompt,
  errorMessage,
  formatModelChoice,
  isAbortError,
  languageName,
  normalizeSettings,
  parseModelChoice,
  parseReviewResult,
  shouldSkipCheck,
  truncate,
} from "./core"

const WRITING_PANEL = "language-tutor.writing"

type CheckResult = Extract<ReviewResult, { mode: "check" }>

type WritingState = {
  status: "pending" | "ready" | "error"
  result?: CheckResult
  error?: string
}

type SessionState = {
  writing?: WritingState
}

type Sessions = Record<string, SessionState>

type Runtime = {
  context: Context
  settings: Store<Settings>
  updateSettings: (mutation: (draft: Settings) => void) => Promise<void>
  sessions: Store<Sessions>
  updateSessions: (mutation: (draft: Sessions) => void) => Promise<void>
  reviews: Map<string, AbortController>
}

let runtime: Runtime | undefined

function useRuntime(): Runtime {
  if (!runtime) throw new Error("Language Tutor is not ready yet")
  return runtime
}

export default Plugin.define({
  id: "local.language-tutor",
  async setup(context) {
    const [settings, updateSettings] = context.storage.store<Settings>(
      "language-tutor.settings",
      { initial: normalizeSettings(context.options.settings ?? context.options) },
    )
    const [sessions, updateSessions] = context.storage.store<Sessions>(
      "language-tutor.sessions",
      { initial: {} },
    )

    const rt: Runtime = {
      context,
      settings,
      updateSettings,
      sessions,
      updateSessions,
      reviews: new Map(),
    }
    runtime = rt

    registerCommands(rt)

    const offInbox = context.data.on("session.inbox.enqueued", (event) => {
      if (event.data.item.type !== "user") return
      const sessionID = event.data.sessionID
      if (sessionID !== activeSessionID(context)) return
      const text = event.data.item.payload.text
      if (!text) return
      if (shouldSkipCheck(text)) {
        patchSession(rt, sessionID, { writing: undefined })
        return
      }
      void runReview(rt, sessionID, text)
    })

    const unregisterStrip = context.ui.slot({
      append: "session.composer.top",
      render: ({ sessionID }) => <TutorStrip sessionID={sessionID} />,
    })

    const unregisterPanel = context.ui.slot({
      append: "session.panel",
      render: (panel) => (
        <Show when={panel.name === WRITING_PANEL}>
          <WritingPanel panel={panel} />
        </Show>
      ),
    })

    return () => {
      offInbox()
      unregisterStrip()
      unregisterPanel()
      for (const controller of rt.reviews.values()) controller.abort()
      if (runtime === rt) runtime = undefined
    }
  },
})

// ---------------------------------------------------------------------------
// Runtime actions
// ---------------------------------------------------------------------------

function activeSessionID(context: Context): string | undefined {
  const route = context.ui.router.current()
  return route.type === "session" ? route.sessionID : undefined
}

function toast(
  rt: Runtime,
  message: string,
  variant: "info" | "success" | "warning" | "error" = "info",
): void {
  rt.context.ui.toast.show({ message, variant, duration: 4000 })
}

function openPanel(rt: Runtime, name: string): boolean {
  if (!activeSessionID(rt.context)) {
    toast(rt, "Open a session first.", "warning")
    return false
  }
  const opened = rt.context.ui.panel.open(name)
  if (!opened) toast(rt, "Could not open the Language Tutor panel.", "warning")
  return opened
}

function snapshotSettings(settings: Settings): Settings {
  return {
    learning: settings.learning,
    native: settings.native,
    check: settings.check,
    ...(settings.model ? { model: { ...settings.model } } : {}),
  }
}

function modelFor(rt: Runtime, settings: Settings): ModelChoice | undefined {
  if (settings.model) return settings.model
  const current = rt.context.ui.model.current()
  if (!current) return undefined
  return {
    providerID: current.providerID,
    id: current.modelID,
    ...(current.variant ? { variant: current.variant } : {}),
  }
}

async function generate(rt: Runtime, prompt: string, signal: AbortSignal): Promise<string> {
  const model = modelFor(rt, snapshotSettings(rt.settings))
  const result = model
    ? await rt.context.client.generate.text({ prompt, model }, { signal })
    : await rt.context.client.generate.text({ prompt }, { signal })
  return result.text
}

function patchSession(rt: Runtime, sessionID: string, patch: Partial<SessionState>): void {
  void rt.updateSessions((draft) => {
    const current = draft[sessionID] ?? (draft[sessionID] = {})
    if ("writing" in patch) current.writing = patch.writing
  })
}

async function runReview(
  rt: Runtime,
  sessionID: string,
  text: string,
): Promise<void> {
  if (!rt.settings.check) return
  const settings = snapshotSettings(rt.settings)

  rt.reviews.get(sessionID)?.abort()
  const controller = new AbortController()
  rt.reviews.set(sessionID, controller)
  patchSession(rt, sessionID, {
    writing: { status: "pending" },
  })

  try {
    const raw = await generate(rt, buildReviewPrompt(text, settings), controller.signal)
    if (controller.signal.aborted) return
    const result = parseReviewResult(raw)
    if (
      !result ||
      result.mode === "skip" ||
      (result.mode === "check" && result.items.length === 0 && !result.rephrase)
    ) {
      patchSession(rt, sessionID, { writing: undefined })
      return
    }
    patchSession(rt, sessionID, {
      writing: { status: "ready", result },
    })
  } catch (error) {
    if (controller.signal.aborted || isAbortError(error)) return
    patchSession(rt, sessionID, {
      writing: {
        status: "error",
        error: errorMessage(error),
      },
    })
  } finally {
    if (rt.reviews.get(sessionID) === controller) rt.reviews.delete(sessionID)
  }
}

async function setSettings(rt: Runtime, patch: Partial<Settings>): Promise<void> {
  await rt.updateSettings((draft) => {
    if (patch.learning !== undefined) draft.learning = patch.learning
    if (patch.native !== undefined) draft.native = patch.native
    if (patch.check !== undefined) draft.check = patch.check
    if ("model" in patch) draft.model = patch.model
  })
}

async function resetSettings(rt: Runtime): Promise<void> {
  await rt.updateSettings((draft) => {
    draft.learning = DEFAULT_SETTINGS.learning
    draft.native = DEFAULT_SETTINGS.native
    draft.check = DEFAULT_SETTINGS.check
    draft.model = undefined
  })
}

function registerCommands(rt: Runtime): void {
  rt.context.keymap.layer(() => ({
    mode: "global",
    priority: 10,
    commands: [
      {
        id: "language-tutor.writing",
        title: "Open writing check",
        description: "Show the full writing feedback for the current session",
        group: "Language Tutor",
        slash: { name: "writing" },
        run: () => {
          openPanel(rt, WRITING_PANEL)
        },
      },
      {
        id: "language-tutor.settings",
        title: "Language Tutor settings",
        description: "Change languages, model, and automatic checking",
        group: "Language Tutor",
        slash: { name: "lang-tu" },
        run: () => {
          void openSettings(rt)
        },
      },
    ],
  }))
}

// ---------------------------------------------------------------------------
// Settings dialogs
// ---------------------------------------------------------------------------

async function openSettings(rt: Runtime): Promise<void> {
  for (;;) {
    const settings = rt.settings
    const choice = await rt.context.ui.dialog.select<string>({
      title: "Language Tutor",
      options: [
        {
          title: "Learning language",
          description: languageName(settings.learning),
          value: "learning",
        },
        {
          title: "Native language",
          description: languageName(settings.native),
          value: "native",
        },
        {
          title: "Writing check",
          description: settings.check ? "On" : "Off",
          value: "check",
        },
        {
          title: "Model",
          description: formatModelChoice(settings.model),
          value: "model",
        },
        {
          title: "Reset all settings",
          description: "Restore the defaults",
          value: "reset",
        },
        { title: "Done", value: "done" },
      ],
    })
    if (!choice || choice === "done") return

    switch (choice) {
      case "learning":
        await chooseLanguage(rt, "learning")
        break
      case "native":
        await chooseLanguage(rt, "native")
        break
      case "check":
        await setSettings(rt, { check: !settings.check })
        toast(rt, `Writing check ${settings.check ? "off" : "on"}`, "success")
        break
      case "model":
        await chooseModel(rt)
        break
      case "reset": {
        const confirmed = await rt.context.ui.dialog.confirm({
          title: "Reset Language Tutor?",
          message: "Restore the default languages and turn automatic checking on.",
          label: { confirm: "Reset", cancel: "Cancel" },
        })
        if (confirmed) {
          await resetSettings(rt)
          toast(rt, "Language Tutor settings reset", "success")
        }
        break
      }
    }
  }
}

async function chooseLanguage(rt: Runtime, field: "learning" | "native"): Promise<void> {
  const value = await rt.context.ui.dialog.select<string>({
    title: field === "learning" ? "Learning language" : "Native language",
    current: rt.settings[field],
    options: LANGUAGES.map((language) => ({
      title: language.name,
      description: language.code,
      value: language.code,
    })),
  })
  if (!value || value === rt.settings[field]) return
  await setSettings(rt, field === "learning" ? { learning: value } : { native: value })
  toast(rt, "Language Tutor settings saved", "success")
}

async function chooseModel(rt: Runtime): Promise<void> {
  const context = rt.context
  let models = context.data.location.model.list(context.location) ?? []
  if (models.length === 0) {
    try {
      await context.data.location.model.sync(context.location)
    } catch {
      // The list below may still be empty; report that instead of failing.
    }
    models = context.data.location.model.list(context.location) ?? []
  }

  const visible = models
    .filter(
      (model) =>
        model.enabled &&
        model.status !== "deprecated" &&
        model.capabilities.input.includes("text") &&
        model.capabilities.output.includes("text"),
    )
    .sort((left, right) => left.name.localeCompare(right.name))

  if (visible.length === 0) {
    await context.ui.dialog.alert({
      title: "Language Tutor",
      message: "No text models are available at this location.",
    })
    return
  }

  const value = await context.ui.dialog.select<string>({
    title: "Model for writing checks",
    current: rt.settings.model ? formatModelChoice(rt.settings.model) : "",
    options: [
      {
        title: "Session model",
        description: "Follow the model selected in the prompt",
        value: "",
      },
      ...visible.map((model) => ({
        title: model.name,
        description: `${model.providerID}/${model.modelID || model.id}`,
        value: `${model.providerID}/${model.modelID || model.id}`,
      })),
    ],
  })
  if (value === undefined) return
  if (value === "") {
    await setSettings(rt, { model: undefined })
    toast(rt, "Writing checks now follow the session model", "success")
    return
  }
  const model = parseModelChoice(value)
  if (!model) return
  await setSettings(rt, { model })
  toast(rt, `Writing-check model set to ${model.id}`, "success")
}

// ---------------------------------------------------------------------------
// UI
// ---------------------------------------------------------------------------

function TutorStrip(props: { sessionID: string }) {
  const rt = useRuntime()
  const writing = () => rt.sessions[props.sessionID]?.writing
  return (
    <Show when={writing()} keyed>
      {(state: WritingState) => (
        <box
          flexDirection="column"
          border={["top"]}
          borderColor={rt.context.theme.border.base}
          paddingTop={1}
          paddingLeft={1}
          paddingRight={1}
        >
          <WritingStrip writing={state} />
        </box>
      )}
    </Show>
  )
}

function WritingStrip(props: { writing: WritingState }) {
  const rt = useRuntime()
  const theme = rt.context.theme
  return (
    <Switch>
      <Match when={props.writing.status === "pending"}>
        <text fg={theme.text.muted}>✏ Checking your writing…</text>
      </Match>
      <Match when={props.writing.status === "error"}>
        <text fg={theme.text.feedback.warning.base} wrapMode="word">
          ✏ Writing check unavailable · {truncate(props.writing.error ?? "", 120)}
        </text>
      </Match>
      <Match when={props.writing.status === "ready" && props.writing.result}>
        <box flexDirection="column" gap={0}>
          <text fg={theme.text.action.primary.base} attributes={1}>
            ✏ Writing check
          </text>
          <CheckBody result={props.writing.result!} compact />
        </box>
      </Match>
    </Switch>
  )
}

function CheckBody(props: { result: CheckResult; compact?: boolean }) {
  const rt = useRuntime()
  const theme = rt.context.theme
  const items = () => (props.compact ? props.result.items.slice(0, 3) : props.result.items)
  return (
    <box flexDirection="column" gap={props.compact ? 0 : 1}>
      <For each={items()}>
        {(item: WritingItem) => (
          <box flexDirection="column" gap={0}>
            <text fg={theme.text.base} wrapMode="word">
              “{item.wrong}” → “{item.right}”
              {props.compact && item.reason ? `  ${truncate(item.reason, 100)}` : ""}
            </text>
            <Show when={!props.compact && item.reason}>
              <text fg={theme.text.muted} wrapMode="word">
                {"  "}
                {item.reason}
              </text>
            </Show>
          </box>
        )}
      </For>
      <Show when={items().length === 0 && !props.result.rephrase}>
        <text fg={theme.text.feedback.success.base}>Looks good.</text>
      </Show>
      <Show when={props.result.rephrase}>
        <text fg={theme.text.muted} wrapMode="word">
          ◇ {props.result.rephrase}
        </text>
      </Show>
    </box>
  )
}

function PanelFrame(props: { title: string; subtitle?: string; footer?: string; children: JSX.Element }) {
  const rt = useRuntime()
  const theme = rt.context.theme
  return (
    <box flexDirection="column" flexGrow={1} width="100%">
      <box
        flexDirection="row"
        justifyContent="space-between"
        paddingLeft={1}
        paddingRight={1}
        paddingBottom={1}
      >
        <text fg={theme.text.base} attributes={1}>
          {props.title}
        </text>
        <Show when={props.subtitle}>
          <text fg={theme.text.faint}>{props.subtitle}</text>
        </Show>
      </box>
      <box flexGrow={1} width="100%">
        {props.children}
      </box>
      <Show when={props.footer}>
        <text fg={theme.text.faint} paddingLeft={1} paddingBottom={1}>
          {props.footer}
        </text>
      </Show>
    </box>
  )
}

function Empty(props: { title: string; hint: string }) {
  const rt = useRuntime()
  const theme = rt.context.theme
  return (
    <box flexDirection="column" padding={2} gap={1}>
      <text fg={theme.text.base} attributes={1}>
        {props.title}
      </text>
      <text fg={theme.text.muted} wrapMode="word">
        {props.hint}
      </text>
    </box>
  )
}

function WritingPanel(props: { panel: PanelInput }) {
  const rt = useRuntime()
  const theme = rt.context.theme
  const writing = () => rt.sessions[props.panel.sessionID]?.writing

  rt.context.keymap.layer(() => ({
    mode: "global",
    priority: 20,
    enabled: () => props.panel.focused,
    commands: [
      {
        id: "language-tutor.writing.close",
        title: "Close writing check",
        bind: "q",
        run: () => rt.context.ui.panel.close(),
      },
    ],
    bindings: ["language-tutor.writing.close"],
  }))

  return (
    <PanelFrame
      title="✏ Writing check"
      subtitle={languageName(rt.settings.learning)}
      footer="q close"
    >
      <Switch>
        <Match when={!writing()}>
          <Empty
            title="No feedback yet"
            hint={`Send a prompt in ${languageName(rt.settings.learning)}. The check runs in the background while the agent works.`}
          />
        </Match>
        <Match when={writing()?.status === "pending"}>
          <box padding={1}>
            <text fg={theme.text.muted}>Checking your writing…</text>
          </box>
        </Match>
        <Match when={writing()?.status === "error"}>
          <box padding={1}>
            <text fg={theme.text.feedback.error.base} wrapMode="word">
              {writing()!.error}
            </text>
          </box>
        </Match>
        <Match when={writing()?.status === "ready" && writing()?.result}>
          <scrollbox flexGrow={1} width="100%" focused={props.panel.focused}>
            <box paddingLeft={1} paddingRight={1} paddingBottom={1}>
              <CheckBody result={writing()!.result!} />
            </box>
          </scrollbox>
        </Match>
      </Switch>
    </PanelFrame>
  )
}
