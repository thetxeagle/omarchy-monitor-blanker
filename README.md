# Monitor Blanker

An Omarchy bar widget for disabling and restoring individual monitors while gaming.

Click the bar icon to open a compact dropdown listing every active or disabled
monitor. Each row exposes the appropriate **Disable** or **Restore** action.

## Features

- **Per-monitor controls** — Disable one output without touching the others.
- **State-aware actions** — Active monitors show **Disable**; disabled monitors show **Restore**.
- **Layout-safe restore** — Reloads your canonical Lua monitor configuration so explicit positions, modes, scales, and transforms return correctly.
- **Omarchy-native UI** — Uses a theme-aware bar widget and dropdown panel.

## Requirements

- Omarchy Quattro with Omarchy Shell.
- Hyprland 0.55 or newer is recommended because the plugin uses `hyprctl eval` and `hl.monitor(...)`.
- No external packages, DDC/CI access, or `sudo` are required.

## Install

```sh
omarchy plugin add https://github.com/thetxeagle/omarchy-monitor-blanker.git --enable
```

Click the monitor icon in the bar, then use each monitor row's **Disable** or
**Restore** button.

## Important behavior

Disabling a monitor removes it from Hyprland's layout, so windows and workspaces
may move to another active output. Restore reloads your user's
`~/.config/hypr/monitors.lua`; keep that file as the source of truth for custom
positions such as a monitor at `0x-2160` with `transform = 2`.

Plugins run as unsandboxed code inside `omarchy-shell`. Review the source before
installing or enabling it.

## Configure placement

```sh
omarchy bar move soulshocker.monitor-sleep --section right
```

## Validate locally

```sh
omarchy plugin validate .
bash -n monitor-blanker
```

## Uninstall

```sh
omarchy plugin remove soulshocker.monitor-sleep
```

## License

MIT. See [LICENSE](LICENSE).
