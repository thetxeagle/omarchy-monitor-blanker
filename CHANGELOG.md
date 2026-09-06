# Changelog

## Unreleased

### Added

- Add a preview screenshot showing the stable Disable/Restore panel.

### Changed

- Update the preview screenshot to show active Disable, disabled Restore, Refresh config, and Restart shell actions.
- Version the README preview URL so GitHub does not reuse a stale cached image.
- Use the namespaced `io.github.omarchy.monitor-blanker` plugin ID required by
  the marketplace, without exposing the maintainer handle.
- Clarify that the plugin requires no elevated privileges.

### Fixed

- Keep last-known disabled monitors visible with a Restore action.
- Add a dedicated Restart shell button.
- Ensure the plugin is placed in the active right bar layout when shell IPC is unavailable during installation.
- Revert the experimental arrangement, rotation, and friendly-name UI to the stable Disable/Restore panel.

## 1.0.3 - 2026-09-04

### Changed

- Rename the user-facing plugin to Monitor Blanker.
- Remove unreliable DPMS Sleep/Wake/Toggle controls.
- Show active and disabled monitors in a bar-anchored dropdown.

### Fixed

- Use Hyprland's current Lua monitor API for Disable/Restore.
- Reload the canonical monitor configuration on Restore to preserve positions and transforms.
