# wezterm-config

My [WezTerm](https://wezterm.org) configuration. Tokyo Night Blackout on a
semi-transparent window, with a tmux-style leader keymap.

## Look

- **Color scheme:** custom *Tokyo Night Blackout* (Tokyo Night palette on a pure
  black `#000000` background, with VSCode's terminal green swapped in)
- **Transparency:** `window_background_opacity = 0.85`
- **Font:** Hack Nerd Font
- **Tab bar:** compact text tabs, always shown, with a date/time clock top-right
- **Chrome:** `RESIZE` only (no OS title bar)

## Requirements

- **WezTerm nightly** — the acrylic/newer options and this config target a recent
  build. The Feb 2024 stable is too old.
- **Hack Nerd Font** — https://github.com/ryanoasis/nerd-fonts/releases
  (install the `Hack` family so glyphs render).

## Install

WezTerm looks for its config at `~/.config/wezterm/wezterm.lua`.

```sh
git clone git@github.com:kdlin/wezterm-config.git ~/.config/wezterm
```

Then launch WezTerm. Config hot-reloads on save (`Ctrl+Shift+R` to force).

## Keys

Leader is `Ctrl+Space` (tmux-style).

| Binding            | Action                |
| ------------------ | --------------------- |
| `LEADER c`         | new tab               |
| `LEADER \|`        | split horizontal      |
| `LEADER -`         | split vertical        |
| `LEADER h/j/k/l`   | move between panes     |
| `LEADER x`         | close pane            |

## Notes

- Cross-platform: macOS gets `macos_window_background_blur`; Windows uses plain
  opacity. The WSL default-domain line is left commented out.
