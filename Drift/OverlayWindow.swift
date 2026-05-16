import AppKit
import SwiftUI

enum OverlayProtectionMode {
    case normal
    case elevated
}

@MainActor
final class OverlayController {
    private var overlays: [ScreenOverlay] = []
    private var driftTimer: Timer?
    private var screenObserver: NSObjectProtocol?
    private var intensity = 1.0
    private var patternCyclingEnabled = true
    private var protectionMode: OverlayProtectionMode = .normal

    func setIntensity(_ intensity: Double) {
        self.intensity = intensity
        applyConfiguration()
    }

    func setPatternCyclingEnabled(_ patternCyclingEnabled: Bool) {
        self.patternCyclingEnabled = patternCyclingEnabled
        applyConfiguration()
    }

    func setProtectionMode(_ protectionMode: OverlayProtectionMode) {
        self.protectionMode = protectionMode
        scheduleDriftTimer()
        applyConfiguration()
    }

    private func applyConfiguration() {
        for overlay in overlays {
            overlay.model.configure(
                intensity: intensity,
                protectionMode: protectionMode,
                patternCyclingEnabled: patternCyclingEnabled
            )
        }
    }

    func start() {
        guard overlays.isEmpty else { return }

        rebuildOverlays()
        scheduleDriftTimer()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.rebuildOverlays()
            }
        }
    }

    func stop() {
        driftTimer?.invalidate()
        driftTimer = nil

        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }

        overlays.forEach { $0.window.orderOut(nil) }
        overlays.removeAll()
    }

    private func rebuildOverlays() {
        overlays.forEach { $0.window.close() }
        overlays = NSScreen.screens.map { screen in
            let model = OverlaySceneModel()
            model.configure(
                intensity: intensity,
                protectionMode: protectionMode,
                patternCyclingEnabled: patternCyclingEnabled
            )
            let window = DriftOverlayWindow(screen: screen, model: model)
            window.orderFrontRegardless()
            return ScreenOverlay(window: window, model: model)
        }
        advanceOverlayState()
    }

    private func advanceOverlayState() {
        for overlay in overlays {
            overlay.model.advance()
        }
    }

    private func scheduleDriftTimer() {
        driftTimer?.invalidate()

        let interval: TimeInterval = protectionMode == .elevated ? 12 : 24
        driftTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceOverlayState()
            }
        }
    }
}

private struct ScreenOverlay {
    let window: DriftOverlayWindow
    let model: OverlaySceneModel
}

private final class DriftOverlayWindow: NSWindow {
    init(screen: NSScreen, model: OverlaySceneModel) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        setFrame(screen.frame, display: false)
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        isMovable = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        animationBehavior = .none
        titleVisibility = .hidden

        contentView = NSHostingView(rootView: OverlayView(model: model).ignoresSafeArea())
    }
}

@MainActor
private final class OverlaySceneModel: ObservableObject {
    private var intensity = 1.0
    private var protectionMode: OverlayProtectionMode = .normal
    private var patternCyclingEnabled = true

    @Published var gradientStart = UnitPoint(x: 0.18, y: 0.22)
    @Published var gradientEnd = UnitPoint(x: 0.82, y: 0.76)
    @Published var highlight = UnitPoint(x: 0.34, y: 0.48)
    @Published var shadow = UnitPoint(x: 0.68, y: 0.52)
    @Published var vignetteCenter = UnitPoint(x: 0.5, y: 0.5)
    @Published var sweepOffsetX = 0.0
    @Published var sweepOffsetY = 0.0
    @Published var sweepAngle = 18.0
    @Published var sheetOpacity = 0.03
    @Published var highlightOpacity = 0.02
    @Published var shadowOpacity = 0.024
    @Published var vignetteOpacity = 0.018
    @Published var sweepOpacity = 0.0

    func configure(intensity: Double, protectionMode: OverlayProtectionMode, patternCyclingEnabled: Bool) {
        self.intensity = intensity
        self.protectionMode = protectionMode
        self.patternCyclingEnabled = patternCyclingEnabled
        advance()
    }

    func advance() {
        let motionRange = protectionMode == .elevated ? 0.08 ... 0.92 : 0.14 ... 0.86
        let animationRange = protectionMode == .elevated ? 10.0 ... 16.0 : 16.0 ... 28.0
        let profileMultiplier = protectionMode == .elevated ? 1.35 : 1.0

        withAnimation(.easeInOut(duration: Double.random(in: animationRange))) {
            gradientStart = UnitPoint(x: Double.random(in: 0.04 ... 0.34), y: Double.random(in: 0.08 ... 0.42))
            gradientEnd = UnitPoint(x: Double.random(in: 0.66 ... 0.96), y: Double.random(in: 0.58 ... 0.92))
            highlight = UnitPoint(x: Double.random(in: motionRange), y: Double.random(in: motionRange))
            shadow = UnitPoint(x: Double.random(in: motionRange), y: Double.random(in: motionRange))
            vignetteCenter = UnitPoint(x: Double.random(in: motionRange), y: Double.random(in: motionRange))
            sheetOpacity = scaledOpacity(in: 0.018 ... 0.05, cap: 0.14, multiplier: profileMultiplier)
            highlightOpacity = scaledOpacity(in: 0.012 ... 0.032, cap: 0.10, multiplier: profileMultiplier)
            shadowOpacity = scaledOpacity(in: 0.014 ... 0.038, cap: 0.11, multiplier: profileMultiplier)
            vignetteOpacity = scaledOpacity(in: 0.010 ... 0.026, cap: 0.08, multiplier: profileMultiplier)

            if patternCyclingEnabled {
                sweepOpacity = scaledOpacity(in: 0.008 ... 0.024, cap: 0.07, multiplier: profileMultiplier)
                sweepOffsetX = Double.random(in: protectionMode == .elevated ? -0.32 ... 0.32 : -0.18 ... 0.18)
                sweepOffsetY = Double.random(in: protectionMode == .elevated ? -0.24 ... 0.24 : -0.14 ... 0.14)
                sweepAngle = Double.random(in: protectionMode == .elevated ? -34 ... 34 : -22 ... 22)
            } else {
                sweepOpacity = 0
                sweepOffsetX = 0
                sweepOffsetY = 0
                sweepAngle = 0
            }
        }
    }

    private func scaledOpacity(in range: ClosedRange<Double>, cap: Double, multiplier: Double = 1.0) -> Double {
        min(Double.random(in: range) * intensity * multiplier, cap)
    }
}

private struct OverlayView: View {
    @ObservedObject var model: OverlaySceneModel

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(model.sheetOpacity),
                                Color.white.opacity(model.sheetOpacity * 0.35),
                                Color.black.opacity(model.sheetOpacity * 0.85)
                            ],
                            startPoint: model.gradientStart,
                            endPoint: model.gradientEnd
                        )
                    )

                Circle()
                    .fill(Color.white.opacity(model.highlightOpacity))
                    .frame(width: proxy.size.width * 0.62, height: proxy.size.width * 0.62)
                    .blur(radius: 180)
                    .position(x: proxy.size.width * model.highlight.x, y: proxy.size.height * model.highlight.y)

                Circle()
                    .fill(Color.black.opacity(model.shadowOpacity))
                    .frame(width: proxy.size.width * 0.78, height: proxy.size.width * 0.78)
                    .blur(radius: 220)
                    .position(x: proxy.size.width * model.shadow.x, y: proxy.size.height * model.shadow.y)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(model.sweepOpacity),
                                Color.black.opacity(model.sweepOpacity * 0.75),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: proxy.size.width * 0.26, height: proxy.size.height * 1.6)
                    .blur(radius: 32)
                    .rotationEffect(.degrees(model.sweepAngle))
                    .offset(x: proxy.size.width * model.sweepOffsetX, y: proxy.size.height * model.sweepOffsetY)
                    .blendMode(.softLight)

                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(model.vignetteOpacity)
                            ],
                            center: model.vignetteCenter,
                            startRadius: min(proxy.size.width, proxy.size.height) * 0.18,
                            endRadius: max(proxy.size.width, proxy.size.height) * 0.86
                        )
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
