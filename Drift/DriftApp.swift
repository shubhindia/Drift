import AppKit
import SwiftUI

@main
struct DriftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var activityManager = ActivityManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(activityManager: activityManager)
        } label: {
            Label("Drift", systemImage: activityManager.isEnabled ? "sparkle" : "moon.zzz")
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

private struct MenuBarView: View {
    @ObservedObject var activityManager: ActivityManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Drift")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("Stay active. Stay subtle.")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusBadge(isEnabled: activityManager.isEnabled)
            }

            VStack(alignment: .leading, spacing: 10) {
                Button(action: activityManager.toggleRequested) {
                    HStack {
                        Image(systemName: activityManager.isEnabled ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(activityManager.isEnabled ? "Disable Drift Mode" : "Enable Drift Mode")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(activityManager.isEnabled ? .gray : .primary)

                HStack {
                    Label(activityManager.statusText, systemImage: activityManager.isEnabled ? "bolt.fill" : "figure.seated.side")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Overlay Strength")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(activityManager.overlayIntensityLabel)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $activityManager.overlayIntensity, in: 0.3 ... 3.0)

                    HStack {
                        Text("Subtle")
                        Spacer()
                        Text("Visible")
                    }
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                }
                .padding(10)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $activityManager.patternCyclingEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pattern Cycling")
                            Text("Adds a moving sweep and shifting edge bias")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .toggleStyle(.switch)

                    Toggle(isOn: $activityManager.autoLowRiskEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto Low-Risk Mode")
                            Text(activityManager.lowRiskModeActive ? "Elevated protection is active" : "Escalates overlay motion after a set AFK interval")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .toggleStyle(.switch)

                    if activityManager.autoLowRiskEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Escalate After")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(activityManager.lowRiskDelayLabel)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: $activityManager.lowRiskDelayMinutes, in: 10 ... 120, step: 5)

                            HStack {
                                Text("Sooner")
                                Spacer()
                                Text("Later")
                            }
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(10)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if !activityManager.accessibilityGranted {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Accessibility permission is required for subtle mouse movement.", systemImage: "hand.raised.fill")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    Button("Open System Settings") {
                        activityManager.openAccessibilitySettings()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(10)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if let lastError = activityManager.lastError {
                Text(lastError)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Divider()

            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("Quit Drift")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 320)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.black.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
}

private struct StatusBadge: View {
    let isEnabled: Bool

    var body: some View {
        Text(isEnabled ? "Active" : "Idle")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isEnabled ? Color.green.opacity(0.18) : Color.white.opacity(0.08), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(isEnabled ? Color.green.opacity(0.35) : Color.white.opacity(0.12), lineWidth: 1)
            }
    }
}
