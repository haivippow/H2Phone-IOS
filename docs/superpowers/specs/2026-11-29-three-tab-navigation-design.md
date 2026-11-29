# Three-tab Navigation Design

## Intent

Make the primary navigation match the three jobs users perform most often: control the active fake profile, choose target applications, and configure profile generation.

## Selected design

- **Điều khiển** is the default tab. It shows the active profile, opens Change, and links to full profile history.
- **APP** is a first-class tab rather than a modal sheet. It discovers installed applications, supports search/filtering, and edits per-app options.
- **Setting** is a first-class tab rather than a gear destination. It owns all generation ranges and capability toggles.
- Full profile history remains reachable from Điều khiển so it does not consume a fourth tab.
- Change uses the existing coherent generator and native activation service. The confirmation screen describes only operations that actually run.

## Safety boundary

This change activates fake profile data for applications with **Fake Info** enabled. It does not implement destructive application-container cleanup or claim that backup/restore has completed. Existing backup selections remain visible for future workflow work, but Change clearly marks them as not executed in this release.

## Approaches considered

Keeping APP and Setting as sheets preserves the current hierarchy but hides primary tasks and creates extra taps. A four-tab layout preserves Profile history but overcrowds compact phones. The selected three-tab layout keeps primary tasks persistent and moves secondary history one level deeper.
