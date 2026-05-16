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
