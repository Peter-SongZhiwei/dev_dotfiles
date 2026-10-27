import { writeFileSync } from "node:fs"
import { Plugin } from "@opencode/plugin/tui"

// Ring the terminal bell (BEL, 0x07) instead of playing a sound or showing a
// system notification. Options (set through `cli.json` plugin `options`):
//
//   bell        string  characters to write (default "\u0007")
//   done        boolean ring when a turn finishes (default true)
//   needsInput  boolean ring when input is needed (default true)
//   allSessions boolean ring for background sessions too (default false)

const TTY = "/dev/tty"

type Settings = {
  bell: string
  done: boolean
  needsInput: boolean
  allSessions: boolean
}

type Route = { type: string; sessionID?: string }

type Event = { type: string; data?: Record<string, any> }

type Context = {
  options?: Record<string, unknown>
  ui: { router: { current(): Route | undefined } }
  data: {
    session: { root(sessionID: string): string }
    on(event: string, handler: (event: Event) => void): () => void
  }
}

function settings(options: Record<string, unknown> | undefined): Settings {
  const value = options ?? {}
  return {
    bell: typeof value.bell === "string" ? value.bell : "\u0007",
    done: value.done !== false,
    needsInput: value.needsInput !== false,
    allSessions: value.allSessions === true,
  }
}

// The server broadcasts every session's events to each connected TUI, so scope
// the bell to the session this TUI is showing. Without this, other instances,
// other tabs, and background sessions would ring too.
function activeSession(context: Context): string | undefined {
  const route = context.ui.router.current()
  return route?.type === "session" ? route.sessionID : undefined
}

function eventSession(event: Event): string | undefined {
  if (event.type === "form.created") return event.data?.form?.sessionID
  return event.data?.sessionID
}

function ring(bell: string) {
  try {
    writeFileSync(TTY, bell)
  } catch {
    // No controlling terminal, for example a detached or piped run.
  }
}

export default Plugin.define({
  id: "local.bell",
  setup(context: Context) {
    const config = settings(context.options)

    const onExecuted = (event: Event) => {
      if (!config.done) return
      const active = activeSession(context)
      const sessionID = eventSession(event)
      if (!active || !sessionID) return
      // Subagent turns are not turn boundaries; only the shown session and its
      // root end a turn the user is waiting on.
      if (!config.allSessions && sessionID !== active && sessionID !== context.data.session.root(active)) return
      ring(config.bell)
    }

    const onPrompt = (event: Event) => {
      if (!config.needsInput) return
      const active = activeSession(context)
      const sessionID = eventSession(event)
      if (!active || !sessionID) return
      if (config.allSessions) {
        ring(config.bell)
        return
      }
      // Prompts from the shown session or its subagents appear in this view.
      if (context.data.session.root(sessionID) !== context.data.session.root(active)) return
      ring(config.bell)
    }

    const stops = [
      context.data.on("session.execution.succeeded", onExecuted),
      context.data.on("session.execution.failed", onExecuted),
      context.data.on("permission.asked", onPrompt),
      context.data.on("form.created", onPrompt),
    ]

    return () => stops.forEach((stop) => stop())
  },
})
