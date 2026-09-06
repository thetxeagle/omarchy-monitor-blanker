# Session: Add monitor identity, arrangement, and refresh controls

**Date**: 2026-09-06
**Branch**: main
**Project**: omarchy-monitor-blanker
**Duration**: Implementation slice

## Summary

Expanded the Omarchy monitor blanker bar widget from disable/restore-only controls into a monitor configuration panel with friendly display identity, resolution/refresh details, rotation, saved arrangement, and re-apply behavior.

## Work Completed

- Read monitor state directly from `hyprctl monitors all -j` to obtain EDID make/model, connector, focused state, geometry, refresh rate, and transform.
- Added friendly monitor labels such as `Samsung Odyssey G81SF (DP-1) — Focused` with resolution and refresh rate below.
- Added per-monitor rotation controls for 0°, 90°, 180°, and 270°.
- Added X/Y arrangement editing and persistence at `~/.config/omarchy-monitor-blanker/monitors.json`.
- Added startup and manual re-apply behavior that reloads Hyprland and reapplies saved monitor positions/transforms.
- Preserved `~/.config/hypr/monitors.lua` as the source of truth for modes and scales.
- Bumped the plugin manifest version to 1.1.0 and documented the user-visible behavior.

## Files Changed

### Created

- `sessions/2026-09-06-omarchy-monitor-controls.md`

### Modified

- `BarWidget.qml`
- `monitor-blanker`
- `manifest.json`
- `README.md`
- `CHANGELOG.md`
- `SCRATCHPAD.md`

## Decisions Made

- Keep persistent state in a plugin-owned JSON file instead of rewriting the user's Hyprland Lua configuration.
- Store only arrangement positions and transforms; leave monitor modes and scales to `monitors.lua`.
- Use coordinate controls for the first arrangement UI slice because they are deterministic and keyboard-accessible inside the existing panel.

## Testing Notes

- `bash -n monitor-blanker`: passed.
- `python3 -m json.tool manifest.json`: passed.
- `git diff --check`: passed.
- `omarchy plugin validate .`: completed without validation output.
- `qmllint` was not installed in the environment.

## Next Steps

- [ ] Install/update the plugin in a live Omarchy shell and verify EDID labels, rotation, save/re-apply, and restore behavior on attached displays.
- [ ] If desired after live testing, replace coordinate inputs with a graphical drag canvas.

## Notes

No user configuration files or `/usr/share/omarchy` files were modified.
