# Changelog

## Unreleased

### Added

- Add a preview screenshot to the repository and README.

### Changed

- Use the namespaced `io.github.omarchy.monitor-blanker` plugin ID required by
  the marketplace, without exposing the maintainer handle.
- Clarify that the plugin requires no elevated privileges.
- Replace the re-apply switch with an explicit button and show saved/unsaved arrangement status.

### Fixed

- Correct the arrangement save argument validation so the saved JSON and managed Hyprland Lua overlay are actually written.
- Keep arrangement tiles fixed-size and centered instead of scaling them to native monitor resolution.

## 1.1.0 - 2026-09-06

### Added

- Show monitor make/model, connector name, focused state, resolution, and refresh rate.
- Add per-monitor rotation controls for 0°, 90°, 180°, and 270°.
- Add saved X/Y arrangement controls under `~/.config/omarchy-monitor-blanker/monitors.json`.
- Replace coordinate inputs with a drag-and-drop arrangement canvas.
- Add a re-apply toggle that reloads Hyprland and reapplies the saved monitor configuration.

## 1.0.3 - 2026-09-04

### Changed

- Rename the user-facing plugin to Monitor Blanker.
- Remove unreliable DPMS Sleep/Wake/Toggle controls.
- Show active and disabled monitors in a bar-anchored dropdown.

### Fixed

- Use Hyprland's current Lua monitor API for Disable/Restore.
- Reload the canonical monitor configuration on Restore to preserve positions and transforms.
