# Monitor Blanker

An Omarchy bar widget for disabling and restoring individual monitors while gaming.

Click the bar icon to open a compact dropdown listing every active or disabled
monitor. Each row exposes the appropriate **Disable** or **Restore** action.

![Monitor Blanker dropdown](preview.png?version=060b9df)

## Features

- **Per-monitor controls** — Disable one output without touching the others.
- **State-aware actions** — Active monitors show **Disable**; disabled monitors show **Restore**.
- **Refresh config** — Reload the user's canonical Hyprland monitor configuration on demand.
- **Shell recovery** — Restart Omarchy Shell directly from the panel.
- **Layout-safe restore** — Reloads your canonical Lua monitor configuration so explicit positions, modes, scales, and transforms return correctly.
- **Omarchy-native UI** — Uses a theme-aware bar widget and dropdown panel.

## Requirements

- Omarchy Quattro with Omarchy Shell.
- Hyprland 0.55 or newer is recommended because the plugin uses `hyprctl eval` and `hl.monitor(...)`.
- No external packages, DDC/CI access, or elevated privileges are required.

## Install

```sh
omarchy plugin add https://github.com/thetxeagle/omarchy-monitor-blanker.git --enable
```

Click the monitor icon in the bar, then use the monitor rows. Click
**Refresh config** when a monitor returns in a bad state, or **Restart shell**
if the widget itself needs to be reloaded.

## Important behavior

Disabling a monitor removes it from Hyprland's layout, so windows and workspaces
may move to another active output. Restore reloads your user's
`~/.config/hypr/monitors.lua` so explicit positions, modes, scales, and
transforms return correctly.

Plugins run as unsandboxed code inside `omarchy-shell`. Review the source before
installing or enabling it.

## Configure placement

```sh
omarchy bar move io.github.omarchy.monitor-blanker --section right
```

## Validate locally

```sh
omarchy plugin validate .
bash -n monitor-blanker
```

## Uninstall

```sh
omarchy plugin remove io.github.omarchy.monitor-blanker
```

## License

MIT. See [LICENSE](LICENSE).
