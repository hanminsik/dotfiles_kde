local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font('Adwaita Mono', { weight = 'Regular' })
config.font_size = 16.0
config.line_height = 1.1

config.color_scheme = 'Thayer Bright'
config.window_background_opacity = 0.95

config.hide_tab_bar_if_only_one_tab = false

config.enable_scroll_bar = true

return config
