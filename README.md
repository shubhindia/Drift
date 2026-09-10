# Drift

Stay active. Stay subtle.

Drift is a lightweight native macOS menu bar utility that keeps the display awake, simulates tiny periodic mouse movement, and applies a nearly invisible drifting overlay to slightly vary pixel output over time on OLED displays.

## Screenshots

![Menu Bar UI](docs/screenshots/menu-bar-ui.png)
![Overlay Protection](docs/screenshots/overlay-protection.png)

## MVP

- Menu bar-only macOS app with no Dock icon
- Single Drift Mode toggle and status indicator
- Power assertions to prevent display and idle sleep
- Small humanized mouse jiggle cadence
- Transparent multi-monitor overlay with slow graphite drift
- Accessibility permission onboarding

## Build

Open `Drift.xcodeproj` in Xcode 26 or newer and run the `Drift` target on macOS Sonoma or later.

The app needs Accessibility permission to simulate input events.

To build the unsigned Release app and local DMG from the command line:

```sh
scripts/build_local_dmg.sh
```

The DMG is written to `build/dist/Drift-local.dmg`. Pass a custom DMG name as
the first argument, for example `scripts/build_local_dmg.sh Drift-test`.

## Release

The workflow uses `scripts/create_dmg.sh` and only depends on tools already available on GitHub's macOS runners.

Current caveat: the produced app and DMG are not signed or notarized yet, so macOS Gatekeeper will treat them as unsigned downloads until signing and notarization are added.
