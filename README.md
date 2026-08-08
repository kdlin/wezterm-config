# wezterm-config

My [WezTerm](https://wezterm.org) configuration. OLED-black, semi-transparent,
tmux-style leader keymap, and a built-in timer system in the tab bar.

Cross-platform: Windows and macOS both work from this single file.

---

## Fresh machine setup

Four steps. Order matters only for the font (install it before first launch, or
the tab bar renders with fallback glyphs).

### 1. Install WezTerm

**Nightly, not stable.** The Feb 2024 stable release is too old for the options
used here.

| Platform | Command |
| --- | --- |
| Windows | `winget install wez.wezterm --version Nightly` or grab the nightly `.exe` from [releases](https://github.com/wezterm/wezterm/releases/tag/nightly) |
| macOS | `brew install --cask wezterm@nightly` |

### 2. Install Hack Nerd Font

Both `config.font` and `config.window_frame.font` reference **Hack Nerd Font**.
Without it, WezTerm silently falls back and the powerline/timer glyphs break.

- Download: https://github.com/ryanoasis/nerd-fonts/releases (`Hack.zip`)
- Windows: unzip, select all `.ttf`, right-click → *Install for all users*
- macOS: `brew install --cask font-hack-nerd-font`

Verify: `wezterm ls-fonts --list-system | grep -i "Hack Nerd"`

### 3. Install Git for Windows (Windows only)

On Windows this config sets `default_prog` to Git Bash, hardcoded at:

```
C:\Program Files\Git\usr\bin\bash.exe
```

Install with `winget install Git.Git` and accept the default install location.
If Git lives somewhere else on that machine, edit the path in `wezterm.lua`
(search for `default_prog`) or WezTerm will fail to spawn a shell.

macOS needs nothing here: no `default_prog` is set, so it uses your login shell.

### 4. Clone this repo into place

WezTerm looks for its config at `~/.config/wezterm/wezterm.lua` on both
platforms.

```sh
git clone git@github.com:kdlin/wezterm-config.git ~/.config/wezterm
```

Launch WezTerm. That's the whole setup. The config hot-reloads on save
(`Ctrl+Shift+R` forces a reload).

---

## What you get

### Look

- **Color scheme:** `ChatGPT` (active). Monochrome-first, hierarchy from
  luminance rather than hue, accent `#10A37F` used in exactly one place.
- **Also bundled:** `Tokyo Night Blackout`. Switch by changing
  `config.color_scheme` near the top of the file.
- **Background:** pure black `#000000` at `0.85` opacity on Windows, `0.8` plus
  a 50px blur on macOS.
- **Tab bar:** compact text tabs, always visible, titles hard-capped at 10 chars.
- **Right status:** live timers (left of the clock) + `YYYY-MM-DD HH:MM`.
- **Chrome:** `RESIZE` only, no OS title bar.
- **Cursor:** steady block, no blink (avoids flicker during streaming output).

### Power / performance

Tuned for battery on a laptop:

| Setting | Value | Why |
| --- | --- | --- |
| `animation_fps` | `1` | minimizes repaints for easing/blink/bell |
| `cursor_blink_rate` | `0` | WezTerm docs call blink re-render "relatively costly" |
| `webgpu_power_preference` | `LowPower` | pins the integrated GPU |
| `front_end` | `WebGpu` | OpenGL causes a gamma/washout bug on some drivers |
| `max_fps` | `60` | |

---

## Keys

Leader is `Ctrl+Space` (tmux-style), 1s timeout. Default WezTerm bindings stay
on; everything below is additive.

### Panes and tabs

| Binding | Action |
| --- | --- |
| `LEADER c` | new tab |
| `LEADER \|` | split horizontal |
| `LEADER -` | split vertical |
| `LEADER h/j/k/l` | move between panes (vim directions) |
| `LEADER x` | close pane (with confirm) |
| `Alt 1`..`Alt 8` | jump to tab 1-8 |
| `Alt 9` | jump to last tab |
| `Ctrl T` | new tab |
| `Ctrl W` | close tab (with confirm) |

> `Ctrl T` and `Ctrl W` deliberately shadow readline's *transpose-chars* and
> *delete-word-backward* inside any shell running in WezTerm. Accepted tradeoff.

### Timers

Countdowns render in the tab bar and fire a desktop notification on completion.
Durations accept `5m`, `90s`, `1h30m`, or a bare number (= minutes), each
optionally followed by a label: `20m Break`.

| Binding | Action |
| --- | --- |
| `LEADER t` | start a timer (prompts for duration + optional label) |
| `LEADER p` | pause/resume the most recent timer |
| `LEADER =` | add time to the most recent timer |
| `LEADER d` | cancel the most recent timer |
| `LEADER T` | clear all timers |

Timer state lives in `wezterm.GLOBAL`, so it survives the config hot-reload that
happens on every save of `wezterm.lua`.

---

## Notes for future edits

`wezterm.lua` carries inline notes on things already tried and reverted. The
short version:

- **Do not add a fake glass/glow effect.** Three attempts failed. `config.background`
  in particular *kills transparency* entirely, because background layers replace
  the window background.
- **Do not switch `front_end` to OpenGL.** It fixes flicker but washes out all
  color (a known driver bug). Try `"Software"` instead if flicker returns.
- **WSL:** the `default_domain = "WSL:Ubuntu-24.04"` line is present but
  commented out. Uncomment once WSL Ubuntu is installed.

## Not included

The shell prompt itself is not part of this repo. On Windows the terminal drops
into Git Bash with whatever `~/.bashrc` that machine has. Set that up separately
if the prompt matters.
