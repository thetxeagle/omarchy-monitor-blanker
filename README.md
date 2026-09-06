# Monitor Blanker

An Omarchy bar widget for disabling and restoring individual monitors while gaming.

Click the bar icon to open a compact dropdown listing every active or disabled
monitor. Each row shows the EDID display name, connector, focused state,
resolution, refresh rate, rotation, and the appropriate **Disable** or
**Restore** action.

Identical monitors are distinguished by their connector name, for example
`Samsung Odyssey G81SF (DP-1)` and `Samsung Odyssey G81SF (DP-2)`.

![Monitor Blanker dropdown](preview.png)

## Features

- **Per-monitor controls** — Disable one output without touching the others.
- **State-aware actions** — Active monitors show **Disable**; disabled monitors show **Restore**.
- **Friendly display identity** — Shows the monitor make/model with its connector, such as `Samsung Odyssey G81SF (DP-1) — Focused`.
- **Rotation control** — Apply 0°, 90°, 180°, or 270° per monitor.
- **Saved arrangement** — Drag displays into position; every drop magnetically attaches the tile to the nearest legal neighboring edge, with no gap or overlap. Saved layouts live at `~/.config/omarchy-monitor-blanker/monitors.json`.
- **Re-apply control** — Reload Hyprland and re-apply the saved arrangement when a display returns in a bad state.
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

Click the monitor icon in the bar, then use the monitor rows and Arrangement
section. Saving an arrangement stores a small JSON file in your user config;
the plugin applies it when the widget starts and after saving. **Re-apply
config** additionally reloads Hyprland before applying it.

Disabled outputs remain in the panel using a last-known monitor cache, so they
can still be restored even when Hyprland temporarily omits them from its live
monitor list.

When an arrangement is saved, the plugin also adds a managed `dofile(...)`
include to `~/.config/hypr/monitors.lua` and writes its monitor rules to the
plugin config directory. This keeps the saved positions and rotations active
across Hyprland reloads without replacing your existing monitor comments or
mode/scale settings.

## Important behavior

Disabling a monitor removes it from Hyprland's layout, so windows and workspaces
may move to another active output. Restore reloads your user's
`~/.config/hypr/monitors.lua`, then reapplies the saved plugin arrangement.
Keep `monitors.lua` as the source of truth for modes and scales; the plugin
stores only positions and transforms.

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
