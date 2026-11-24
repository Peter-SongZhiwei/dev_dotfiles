import { MouseRegion, type Component, type TUI } from '@earendil-works/pi-tui'

/** Clip a widget until it is clicked, then toggle between clipped and full content. */
export function collapsibleRows(component: Component, collapsedRows: number, tui: TUI): Component {
  let expanded = false
  const collapsible: Component = {
    render(width: number): string[] {
      const lines = component.render(width)
      return expanded ? lines : lines.slice(0, collapsedRows)
    },
    invalidate(): void {
      component.invalidate()
    }
  }

  return new MouseRegion(collapsible, (event) => {
    if (event.type !== 'click' || event.button !== 'left') return undefined
    expanded = !expanded
    collapsible.invalidate()
    tui.requestRender()
    return { handled: true }
  })
}
