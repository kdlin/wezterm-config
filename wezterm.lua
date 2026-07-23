local wezterm = require("wezterm")
local config = wezterm.config_builder()

local is_windows = os.getenv("OS") and os.getenv("OS"):lower():find("windows")
local is_macos = wezterm.target_triple:lower():find("darwin") ~= nil

-- Tokyo Night Blackout (Tokyo Night palette on a pure-black background)
config.color_schemes = {
	["Tokyo Night Blackout"] = {
		foreground = "#c0caf5",
		background = "#000000",
		cursor_bg = "#c0caf5",
		cursor_fg = "#000000",
		cursor_border = "#c0caf5",
		selection_bg = "#283457",
		selection_fg = "#c0caf5",
		ansi = { "#15161e", "#f7768e", "#0dbc79", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#a9b1d6" },
		brights = { "#414868", "#f7768e", "#23d18b", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#c0caf5" },
		tab_bar = {
			background = "#000000",
			active_tab = { bg_color = "#7aa2f7", fg_color = "#000000" },
			inactive_tab = { bg_color = "#000000", fg_color = "#565f89" },
			inactive_tab_hover = { bg_color = "#15161e", fg_color = "#c0caf5" },
			new_tab = { bg_color = "#000000", fg_color = "#565f89" },
			new_tab_hover = { bg_color = "#15161e", fg_color = "#c0caf5" },
		},
	},
}

-- ui
config.color_scheme = "Tokyo Night Blackout"
config.max_fps = 120
config.font = wezterm.font("Hack Nerd Font", { weight = "Regular" })

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false -- always show tabs (like his tmux bar)
config.use_fancy_tab_bar = false -- compact text tabs, closer to the tmux look
config.tab_bar_at_bottom = false
config.tab_max_width = 32
config.window_decorations = "RESIZE"

-- Date/time in the top-right of the tab bar (his tmux showed this)
wezterm.on("update-right-status", function(window, _pane)
	window:set_right_status(wezterm.format({
		{ Foreground = { Color = "#565f89" } },
		{ Text = wezterm.strftime("%Y-%m-%d %H:%M ") },
	}))
end)
config.window_frame = {
	font = wezterm.font("Hack Nerd Font", { weight = "Bold" }),
}

config.inactive_pane_hsb = {
	saturation = 0.0,
	brightness = 0.5,
}

if is_windows then
	-- Plain opacity (WezTerm's own alpha) instead of Acrylic, which renders
	-- solid gray unless Windows "Transparency effects" is enabled AND the DWM
	-- composition supports it. This is reliable everywhere.
	config.window_background_opacity = 0.85
	config.window_frame.font_size = 10.0
end

if is_macos then
	config.window_background_opacity = 0.8
	config.macos_window_background_blur = 50
	config.font_size = 15.0
	config.window_frame.font_size = 13.0
end

-- shell
-- Kun sets config.default_domain = "WSL:Ubuntu-24.04" here.
-- Kept on PowerShell per your choice. Uncomment once WSL Ubuntu is installed:
-- if is_windows then
-- 	config.default_domain = "WSL:Ubuntu-24.04"
-- end

-- keys
-- Kun's leader (tmux-style). His full keymap was cut off in the video and is
-- macOS-centric (CMD keys, disable_default_key_bindings = true), so defaults are
-- left ON here and only Windows-safe leader bindings are added.
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	-- new tab (his leader-c)
	{ key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	-- pane splits
	{ key = "|", mods = "LEADER|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	-- move between panes
	{ key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
	-- close pane
	{ key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
}

return config
