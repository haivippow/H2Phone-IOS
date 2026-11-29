# Coherent Device Randomization Design

## Intent

Make **Change** generate and activate a real fake-device profile instead of only storing UI choices. Every generated profile must describe one internally consistent iPhone and one firmware that can run on that iPhone.

## Goals

- Select one exact AppleDB `ProductType` and one board belonging to it.
- Select an iOS version/build/Darwin tuple compatible with that `ProductType` and the configured ranges.
- Derive model-dependent hardware values from a reviewed local specification table, never by independent random choices.
- Generate identifiers and variable values once, persist the complete profile atomically, and expose it to the tweak for selected apps.
- Preserve the existing profile-range settings and fail safely when no compatible combination exists.

## Non-goals

- Implement application backup, restore, or data cleaning.
- Claim that mutable identifiers such as IMEI are manufacturer-issued values.
- Hook `UIScreen` natively; browser screen spoofing remains isolated to JavaScript.

## Constraints

- No runtime network access; generated catalogs are reviewed and bundled.
- Existing config files migrate without losing selected applications.
- The standard rootless and RootHide packaging paths remain supported.
- No commits or pushes unless the user explicitly requests `push`.

## Approach

The rejected minimal approach would only map marketing names to ProductType/board; it would still permit impossible firmware and hardware combinations. A second option would query AppleDB at runtime, but that makes Change network-dependent and mutable.

The selected approach extends the build-time catalog with compatible firmware tuples, adds a reviewed hardware-spec table for supported marketing models, and introduces a pure Swift profile generator. The generated dictionary is passed through an Objective-C bridge to `H2ConfigManager`, whose schema stores a complete custom profile rather than an index into four presets. The tweak continues consuming the same profile keys.

## Safety behavior

If the selected ranges contain no complete device/spec/firmware combination, Change returns a visible error and does not alter the current config. Missing or malformed bundled data also fails closed. Config writes remain atomic.
