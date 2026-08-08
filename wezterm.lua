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

	-- ChatGPT (reverse-engineered design system, see
	-- ~/Downloads/ChatGPT_Reverse_Engineered_Design_System.md).
	-- Monochrome-first: hierarchy comes from luminance, not hue. The accent
	-- (#10A37F) appears in exactly one place -- the cursor -- per the doc's
	-- "accent used sparingly" rule. Normal ANSI row = semantic tokens,
	-- bright row = the doc's GitHub Dark syntax palette.
	["ChatGPT"] = {
		foreground = "#E6EDF3", -- code-block foreground (terminal text is code)
		background = "#000000", -- --bg-primary, OLED black
		-- Cursor is a muted white rather than the accent. WezTerm draws the
		-- cursor opaque (alpha on cursor_bg is not honored), so "transparent
		-- white" is faked with --text-secondary luminance instead of an alpha
		-- channel. Drop to #A0A0A0 (--text-muted) if this still reads too hot.
		cursor_bg = "#D0D0D0", -- --text-secondary
		cursor_fg = "#000000",
		cursor_border = "#D0D0D0",
		selection_bg = "#2B2B2B", -- --border
		selection_fg = "#FFFFFF", -- --text-primary
		-- normal: --bg-surface, --error, --accent, --warning, then GitHub Dark
		-- blue/purple/cyan (the doc defines no cool-hue semantics), --text-secondary
		ansi = { "#171717", "#EF4444", "#10A37F", "#F59E0B", "#58A6FF", "#A371F7", "#39C5CF", "#D0D0D0" },
		-- bright: --text-disabled, then keyword/class/variable/number/function/string, --text-primary
		brights = { "#6F6F6F", "#FF7B72", "#7EE787", "#FFA657", "#79C0FF", "#D2A8FF", "#A5D6FF", "#FFFFFF" },
		tab_bar = {
			background = "#000000", -- --bg-primary
			active_tab = { bg_color = "#171717", fg_color = "#FFFFFF" }, -- --bg-surface elevation
			inactive_tab = { bg_color = "#000000", fg_color = "#6F6F6F" }, -- --text-disabled
			inactive_tab_hover = { bg_color = "#222222", fg_color = "#D0D0D0" }, -- --bg-hover
			new_tab = { bg_color = "#000000", fg_color = "#6F6F6F" },
			new_tab_hover = { bg_color = "#222222", fg_color = "#D0D0D0" },
		},
	},
}

-- ui
config.color_scheme = "ChatGPT"
config.max_fps = 60

-- NOTE for future sessions: do NOT try to fake a glass/glow effect here.
-- Three attempts, all reverted:
--   1. window_background_gradient #141414 -> #000000 -- invisible at 0.85 alpha
--      over a dark desktop.
--   2. A baked plate with a diagonal specular sheen across the middle -- read as
--      a smudge, because it sat directly behind the text.
--   3. A corner/edge rim-light plate via config.background -- KILLED THE
--      TRANSPARENCY. config.background layers replace the window background
--      entirely, so the opaque base layer made the window fully solid and
--      window_background_opacity no longer showed the desktop through.
-- The see-through effect is worth more than any synthetic glow. Flat black.
--
-- Battery. WezTerm's two documented power levers are the blinking cursor
-- (already disabled below -- docs call re-rendering for the blink "relatively
-- costly" and advise turning it off on battery) and animation_fps, which drives
-- redraws for easing, blinking text, and the visual bell. Default is 10;
-- 1 minimizes those repaints. Raise it if easing ever looks choppy.
config.animation_fps = 1

-- Default already prefers the low-power adapter, but pin it so a future
-- WezTerm default change cannot silently move this to the discrete GPU.
config.webgpu_power_preference = "LowPower"
config.font = wezterm.font("Hack Nerd Font", { weight = "Medium" })

-- NOTE: OpenGL was tried here to fix a flicker issue, but it caused a worse
-- problem -- washed-out/grayscale color rendering, a known OpenGL gamma bug
-- on some GPU/driver combos in this WezTerm build (confirmed via WezTerm's
-- own GitHub discussion #4803). Reverted to WebGpu (also nightly's default,
-- known-good colors). If flicker returns, try "Software" instead of OpenGL.
config.front_end = "WebGpu"

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false -- always show tabs (like his tmux bar)
config.use_fancy_tab_bar = false -- compact text tabs, closer to the tmux look
config.tab_bar_at_bottom = false
config.tab_max_width = 32
config.window_decorations = "RESIZE"

-- Compact tab titles: keep the active/inactive colors from tab_bar above,
-- but truncate the text hard so tabs stay readable in a narrow window
-- (e.g. the Alt+Space companion panel) instead of showing the full pane title.
wezterm.on("format-tab-title", function(tab, _tabs, _panes, config_, _hover, max_width)
	local colors = config_.resolved_palette.tab_bar
	local background, foreground
	if tab.is_active then
		background = colors.active_tab.bg_color
		foreground = colors.active_tab.fg_color
	else
		background = colors.inactive_tab.bg_color
		foreground = colors.inactive_tab.fg_color
	end

	local title = tab.tab_title
	if not title or #title == 0 then
		title = tab.active_pane.title
	end
	-- hard cap at 10 chars regardless of tab_max_width, so tabs stay compact
	title = wezterm.truncate_right(title, math.min(10, max_width - 1))

	return {
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = " " .. title .. " " },
	}
end)

-- Cursor: steady (no blink) so it doesn't visibly flicker while Claude Code
-- or any fast-scrolling command is streaming output.
config.cursor_blink_rate = 0
config.default_cursor_style = "SteadyBlock"

-- Timers: LEADER+t to start ("5m", "90s", "1h30m", "20m Break" all work),
-- LEADER+T clears everything. Countdowns render left of the date/time block.
config.status_update_interval = 1000

-- WezTerm hot-reloads this whole file on every save (yours or mine), which
-- re-executes the script from the top. A plain `local timers = {}` gets wiped
-- back to empty on EVERY reload -- that's why timers were "randomly"
-- disappearing (really: disappearing on every config edit). wezterm.GLOBAL is
-- the table WezTerm specifically exempts from that reset, so state stored
-- there survives reloads. `timers` below is a local ALIAS pointing at the same
-- table object -- table.insert/remove on it mutate the persisted table
-- directly, no extra plumbing needed for the table itself.
if not wezterm.GLOBAL.timers then
	wezterm.GLOBAL.timers = {}
end
if not wezterm.GLOBAL.next_timer_id then
	wezterm.GLOBAL.next_timer_id = 1
end
local timers = wezterm.GLOBAL.timers

local function parse_duration(input)
	local total = 0
	local matched = false
	for amount, unit in input:gmatch("(%d+%.?%d*)%s*([hms])") do
		matched = true
		amount = tonumber(amount)
		if unit == "h" then
			total = total + amount * 3600
		elseif unit == "m" then
			total = total + amount * 60
		elseif unit == "s" then
			total = total + amount
		end
	end
	if not matched then
		-- bare number = minutes
		local n = input:match("^%s*(%d+%.?%d*)%s*$")
		if n then
			total = tonumber(n) * 60
			matched = true
		end
	end
	if not matched or total <= 0 then
		return nil
	end
	return math.floor(total)
end

local function format_remaining(secs)
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%02d:%02d", m, s)
end

-- remaining seconds for a timer regardless of paused state
local function time_left(t, now)
	if t.paused then
		return t.remaining
	end
	return t.expires - now
end

wezterm.on("timer-input", function(window, pane, line)
	if not line or line == "" then
		return
	end
	local dur_str, label = line:match("^(%S+)%s*(.-)$")
	local secs = parse_duration(dur_str or line)
	if not secs then
		window:toast_notification("WezTerm Timer", "Couldn't parse duration: " .. line, nil, 4000)
		return
	end
	table.insert(timers, {
		id = wezterm.GLOBAL.next_timer_id,
		label = (label ~= "" and label) or nil,
		expires = os.time() + secs,
		paused = false,
		remaining = nil,
		notified = false,
	})
	-- next_timer_id is a number (value type, not a table), so unlike `timers`
	-- it needs an explicit write-through to GLOBAL -- a local alias would only
	-- rebind the local, not persist the new value.
	wezterm.GLOBAL.next_timer_id = wezterm.GLOBAL.next_timer_id + 1
end)

-- pause/resume, add-time, and cancel all act on the most recent timer
wezterm.on("timer-toggle-pause", function(window, _pane)
	local t = timers[#timers]
	if not t then
		window:toast_notification("WezTerm Timer", "No timer running", nil, 2000)
		return
	end
	local now = os.time()
	if t.paused then
		t.expires = now + t.remaining
		t.paused = false
	else
		t.remaining = t.expires - now
		t.paused = true
	end
end)

wezterm.on("timer-add-time", function(window, pane, line)
	local t = timers[#timers]
	if not t then
		window:toast_notification("WezTerm Timer", "No timer running", nil, 2000)
		return
	end
	local secs = parse_duration(line or "")
	if not secs then
		window:toast_notification("WezTerm Timer", "Couldn't parse duration: " .. tostring(line), nil, 4000)
		return
	end
	if t.paused then
		t.remaining = t.remaining + secs
	else
		t.expires = t.expires + secs
	end
	t.notified = false
end)

wezterm.on("timer-cancel-latest", function(window, _pane)
	if #timers == 0 then
		window:toast_notification("WezTerm Timer", "No timer running", nil, 2000)
		return
	end
	table.remove(timers)
end)

-- Timers (left) + date/time (right) in the tab bar
wezterm.on("update-right-status", function(window, _pane)
	local now = os.time()
	for _, t in ipairs(timers) do
		if not t.paused and now >= t.expires and not t.notified then
			window:toast_notification("WezTerm Timer", (t.label or "Timer") .. " done!", nil, 5000)
			t.notified = true
		end
	end

	local segments = {}
	for _, t in ipairs(timers) do
		local remaining = time_left(t, now)
		local text, color
		-- status colors track the ChatGPT semantic tokens: --error when a timer
		-- fires, --text-muted while paused (recedes), --warning while counting.
		if not t.paused and remaining <= 0 then
			text = (t.label or "Timer") .. " done!"
			color = "#EF4444"
		elseif t.paused then
			text = format_remaining(remaining) .. (t.label and (" " .. t.label) or "") .. " ⏸"
			color = "#A0A0A0"
		else
			text = format_remaining(remaining) .. (t.label and (" " .. t.label) or "")
			color = "#F59E0B"
		end
		table.insert(segments, { Foreground = { Color = color } })
		table.insert(segments, { Text = "⏱ " .. text .. "  " })
	end

	table.insert(segments, { Foreground = { Color = "#6F6F6F" } }) -- --text-disabled
	table.insert(segments, { Text = wezterm.strftime("%Y-%m-%d %H:%M ") })

	window:set_right_status(wezterm.format(segments))
end)
config.window_frame = {
	font = wezterm.font("Hack Nerd Font", { weight = "Bold" }),
}

-- Neutral values (not just removing the old override) -- WezTerm still dims
-- inactive panes by default (saturation=0.9, brightness=0.8) if this isn't
-- explicitly set to 1.0/1.0. All panes stay full color regardless of focus.
config.inactive_pane_hsb = {
	saturation = 1.0,
	brightness = 1.0,
}

-- Browser-style zoom: CTRL +/- changes font size only. Default is true, which
-- keeps rows/cols fixed and resizes the window instead. False keeps the window
-- pixel size and reflows the grid to more/fewer cells.
config.adjust_window_size_when_changing_font_size = false

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
-- No default_prog was set here before, so WezTerm fell back to Windows' raw
-- default shell (cmd.exe) -- no ls, no real cd semantics, no vim niceties.
-- Git Bash gives real Unix commands and matches Claude Code's own Bash tool
-- environment (MINGW64), so anything that works there works here too.
if is_windows then
	config.default_prog = { "C:\\Program Files\\Git\\usr\\bin\\bash.exe", "-l" }
end

-- Kun sets config.default_domain = "WSL:Ubuntu-24.04" here.
-- Kept on Git Bash per your choice. Uncomment once WSL Ubuntu is installed:
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
	-- timers: LEADER+t to set (e.g. "5m", "90s", "1h30m Standup"), LEADER+T to clear all
	{
		key = "t",
		mods = "LEADER",
		action = wezterm.action.PromptInputLine({
			description = "Timer duration [+ optional label], e.g. '5m Break'",
			action = wezterm.action_callback(function(window, pane, line)
				wezterm.emit("timer-input", window, pane, line)
			end),
		}),
	},
	{
		key = "T",
		mods = "LEADER|SHIFT",
		action = wezterm.action_callback(function(window, _pane)
			timers = {}
			window:toast_notification("WezTerm Timer", "All timers cleared", nil, 2000)
		end),
	},
	-- pause/resume the most recent timer
	{
		key = "p",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			wezterm.emit("timer-toggle-pause", window, pane)
		end),
	},
	-- add time to the most recent timer, e.g. "2m", "30s"
	{
		key = "=",
		mods = "LEADER",
		action = wezterm.action.PromptInputLine({
			description = "Add time to current timer, e.g. '2m'",
			action = wezterm.action_callback(function(window, pane, line)
				wezterm.emit("timer-add-time", window, pane, line)
			end),
		}),
	},
	-- cancel just the most recent timer (LEADER+T clears all instead)
	{
		key = "d",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			wezterm.emit("timer-cancel-latest", window, pane)
		end),
	},
	-- Alt+1..9 jump straight to tab N (tabs are 0-indexed internally).
	-- Was briefly Ctrl+1..9 on 2026-07-26, reverted same day back to Alt.
	{ key = "1", mods = "ALT", action = wezterm.action.ActivateTab(0) },
	{ key = "2", mods = "ALT", action = wezterm.action.ActivateTab(1) },
	{ key = "3", mods = "ALT", action = wezterm.action.ActivateTab(2) },
	{ key = "4", mods = "ALT", action = wezterm.action.ActivateTab(3) },
	{ key = "5", mods = "ALT", action = wezterm.action.ActivateTab(4) },
	{ key = "6", mods = "ALT", action = wezterm.action.ActivateTab(5) },
	{ key = "7", mods = "ALT", action = wezterm.action.ActivateTab(6) },
	{ key = "8", mods = "ALT", action = wezterm.action.ActivateTab(7) },
	{ key = "9", mods = "ALT", action = wezterm.action.ActivateTab(-1) }, -- last tab
	-- Plain Ctrl+W closes the current tab (confirm prompt first).
	-- NOTE: this overrides bash/zsh's default Ctrl+W (delete-word-backward)
	-- inside any shell running in WezTerm -- accepted tradeoff, chosen deliberately.
	{ key = "w", mods = "CTRL", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	-- Plain Ctrl+T opens a new tab.
	-- NOTE: this overrides bash/zsh's default Ctrl+T (transpose-chars)
	-- inside any shell running in WezTerm -- accepted tradeoff, chosen deliberately.
	{ key = "t", mods = "CTRL", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
}

return config
