# Changelog

## Unreleased

### Added

- Add a preview screenshot to the repository and README.

### Changed

- Use the namespaced `io.github.omarchy.monitor-blanker` plugin ID required by
  the marketplace, without exposing the maintainer handle.
- Clarify that the plugin requires no elevated privileges.

## 1.0.3 - 2026-09-04

### Changed

- Rename the user-facing plugin to Monitor Blanker.
- Remove unreliable DPMS Sleep/Wake/Toggle controls.
- Show active and disabled monitors in a bar-anchored dropdown.

### Fixed

- Use Hyprland's current Lua monitor API for Disable/Restore.
- Reload the canonical monitor configuration on Restore to preserve positions and transforms.
