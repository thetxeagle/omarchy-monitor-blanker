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
- Added a drag-and-drop arrangement canvas with persistence at `~/.config/omarchy-monitor-blanker/monitors.json`.
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
- Use a bounded drag canvas that converts visual positions back to Hyprland coordinates while preserving the existing JSON format.

## Testing Notes

- `bash -n monitor-blanker`: passed.
- `python3 -m json.tool manifest.json`: passed.
- `git diff --check`: passed.
- `omarchy plugin validate .`: completed without validation output.
- Installed copy validated with `omarchy plugin validate ~/.config/omarchy/plugins/io.github.omarchy.monitor-blanker`.
- Installed copy refreshed with `omarchy-shell shell rescanPlugins`.
- Replaced the ambiguous re-apply switch with an explicit button and added arrangement status text.
- Fixed the save argument validation and changed the canvas to fixed-size centered tiles with a larger editing area.
- Added a managed Lua include so saved arrangements participate in Hyprland reloads.
- `qmllint` was not installed in the environment.

## Next Steps

- [ ] Install/update the plugin in a live Omarchy shell and verify EDID labels, rotation, save/re-apply, and restore behavior on attached displays.
- [ ] Live-test dragging, saving, rotation, restore, and re-apply behavior with attached displays.

## Notes

No user configuration files or `/usr/share/omarchy` files were modified.
