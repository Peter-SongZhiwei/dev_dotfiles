import { Plugin } from "@opencode/plugin"

// Server-side half of the bell plugin.
//
// The terminal alert itself lives in `tui.ts`; this entrypoint exists so
// OpenCode discovers and reports the plugin, which makes the CLI load the TUI
// half. There is nothing for the server to do.
export default Plugin.define({
  id: "local.bell",
  setup() {},
})
