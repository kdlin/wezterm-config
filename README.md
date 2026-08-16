# wezterm-config

My [WezTerm](https://wezterm.org) configuration. OLED-black, semi-transparent,
tmux-style leader keymap, and a built-in timer system in the tab bar.

Monochrome base, [Resend](https://resend.com)'s hues for anything that carries
meaning.

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

**Required.** `config.window_frame.font` uses it outright, and `config.font`
falls back to it for every Nerd Font and powerline glyph in the tab bar.

- Download: https://github.com/ryanoasis/nerd-fonts/releases (`Hack.zip`)
- Windows: unzip, select all `.ttf`, right-click → *Install for all users*
- macOS: `brew install --cask font-hack-nerd-font`

Verify: `wezterm ls-fonts --list-system | grep -i "Hack Nerd"`

**Amazon Ember Mono (optional).** `config.font` prefers it and falls through to
Hack when it is absent, so a fresh machine works with no extra steps. It is
Amazon brand type and not redistributable here, so it is deliberately not a
requirement. Install both weights if you have them:

```
wezterm ls-fonts --list-system | grep -i "Ember Mono"
```

If only one weight is installed, pin it in `config.font` or DirectWrite will
fail to resolve the family.

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

- **Color scheme:** `ChatGPT` (active). Monochrome base: backgrounds, text, and
  cursor are pure greyscale, so hierarchy comes from luminance. Hue is reserved
  for things that mean something — ANSI output, timer state, tab elevation — and
  those hues come from Resend. See [Palette](#palette).
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

## Palette

[resend.com](https://resend.com) is built on [Radix Colors](https://www.radix-ui.com/colors)
and ships only the *alpha* scales, so these are the dark-theme alpha values
composited over `#000000` — what they actually resolve to on Resend's own
black ground.

Radix step 9 is the saturated solid and step 11 the high-contrast variant. Both
are designed to stay legible against the same dark surface, which is exactly the
normal/bright split a terminal needs.

| Role | Normal (step 9) | Bright (step 11) |
| --- | --- | --- |
| red | `#E3464B` | `#FF9592` |
| green | `#2A9E66` | `#3AD389` |
| yellow | `#FFC53D` | `#FFCA16` |
| blue | `#0090FF` | `#70B8FF` |
| magenta | `#6B53CC` | `#BAA7FF` |
| cyan | `#009EC3` | `#4ACAE4` |

Greys drive the surfaces: `#141517` `#191B1E` `#212629` `#3B4345` `#A1A4A5`
`#F0F0F0`. The active tab lifts off black by `gray_3`, the same step Resend uses
to lift a card off the page.

The palette lives in one `local resend` table at the top of `wezterm.lua`.
Nothing downstream hardcodes a hue.

Timer states map to luminance rather than hue, so the bar reads at a glance:

| State | Color |
| --- | --- |
| fired | `red_hi` — brightest, demands attention |
| counting | `amber_hi` — mid |
| paused | `gray_11` — recedes into the bar |
| clock | `#6F6F6F` — ambient, never competes |

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

---

## Credits

- [WezTerm](https://wezterm.org) by Wez Furlong
- [Radix Colors](https://www.radix-ui.com/colors) — the palette underneath the hues
- [Resend](https://resend.com) — the specific dark-theme steps used here
- [Nerd Fonts](https://www.nerdfonts.com/) — Hack Nerd Font

## License

MIT. See [LICENSE](LICENSE).
