-- Neovide-only settings.
-- Neovide's config.toml only accepts startup/CLI options (frame, font, idle, ...);
-- cursor/scroll animations, particle effects and floating-window effects can only be
-- configured through these global variables, so they live here.
if not vim.g.neovide then
    return
end

-- Cursor movement animation
vim.g.neovide_cursor_animation_length = 0.0
vim.g.neovide_cursor_short_animation_length = 0.0
vim.g.neovide_cursor_trail_size = 0.0
vim.g.neovide_cursor_animate_in_insert_mode = false
vim.g.neovide_cursor_animate_command_line = false
vim.g.neovide_cursor_smooth_blink = false

-- Cursor particle effects ("" = no particles)
vim.g.neovide_cursor_vfx_mode = ""
vim.g.neovide_cursor_vfx_opacity = 0.0

-- Window / scroll animation
vim.g.neovide_position_animation_length = 0.0
vim.g.neovide_scroll_animation_length = 0.0
vim.g.neovide_scroll_animation_far_lines = 0

-- Floating window effects
vim.g.neovide_floating_shadow = false
vim.g.neovide_floating_blur_amount_x = 0.0
vim.g.neovide_floating_blur_amount_y = 0.0
vim.g.neovide_floating_corner_radius = 0.0

-- Progress bar animation (0.16+)
vim.g.neovide_progress_bar_enabled = false
