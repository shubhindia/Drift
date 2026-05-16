import Foundation

@MainActor
final class ActivityManager: ObservableObject {
    private enum Defaults {
        static let overlayIntensityKey = "overlayIntensity"
        static let patternCyclingEnabledKey = "patternCyclingEnabled"
        static let autoLowRiskEnabledKey = "autoLowRiskEnabled"
        static let lowRiskDelayMinutesKey = "lowRiskDelayMinutes"
        static let defaultOverlayIntensity = 1.6
        static let defaultPatternCyclingEnabled = true
        static let defaultAutoLowRiskEnabled = true
        static let defaultLowRiskDelayMinutes = 30.0
    }

    @Published private(set) var isEnabled = false
    @Published private(set) var accessibilityGranted = AccessibilityPermissions.isGranted
    @Published private(set) var lastError: String?
    @Published private(set) var lowRiskModeActive = false
    @Published var overlayIntensity: Double {
        didSet {
            UserDefaults.standard.set(overlayIntensity, forKey: Defaults.overlayIntensityKey)
            overlayController.setIntensity(overlayIntensity)
        }
    }
    @Published var patternCyclingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(patternCyclingEnabled, forKey: Defaults.patternCyclingEnabledKey)
            overlayController.setPatternCyclingEnabled(patternCyclingEnabled)
        }
    }
    @Published var autoLowRiskEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoLowRiskEnabled, forKey: Defaults.autoLowRiskEnabledKey)
            refreshProtectionProfile()
        }
    }
    @Published var lowRiskDelayMinutes: Double {
        didSet {
            UserDefaults.standard.set(lowRiskDelayMinutes, forKey: Defaults.lowRiskDelayMinutesKey)
            refreshProtectionProfile()
        }
    }

    private let sleepAssertion = SleepAssertion()
    private let mouseJiggler = MouseJiggler()
    private let overlayController = OverlayController()
    private var permissionPollTimer: Timer?
    private var sessionStartDate: Date?

    var statusText: String {
        if isEnabled, lowRiskModeActive {
            return "Display awake, elevated drift protection active"
        }

        if isEnabled {
            return "Display awake, activity drifting"
        }

        if accessibilityGranted {
            return "Ready when you are"
        }

        return "Waiting for Accessibility access"
    }

    var overlayIntensityLabel: String {
        "\(Int((overlayIntensity / 3.0) * 100))%"
    }

    var lowRiskDelayLabel: String {
        "\(Int(lowRiskDelayMinutes)) min"
    }

    init() {
        let storedIntensity = UserDefaults.standard.object(forKey: Defaults.overlayIntensityKey) as? Double
        let storedPatternCyclingEnabled = UserDefaults.standard.object(forKey: Defaults.patternCyclingEnabledKey) as? Bool
        let storedAutoLowRiskEnabled = UserDefaults.standard.object(forKey: Defaults.autoLowRiskEnabledKey) as? Bool
        let storedLowRiskDelayMinutes = UserDefaults.standard.object(forKey: Defaults.lowRiskDelayMinutesKey) as? Double

        overlayIntensity = storedIntensity ?? Defaults.defaultOverlayIntensity
        patternCyclingEnabled = storedPatternCyclingEnabled ?? Defaults.defaultPatternCyclingEnabled
        autoLowRiskEnabled = storedAutoLowRiskEnabled ?? Defaults.defaultAutoLowRiskEnabled
        lowRiskDelayMinutes = storedLowRiskDelayMinutes ?? Defaults.defaultLowRiskDelayMinutes

        overlayController.setIntensity(overlayIntensity)
        overlayController.setPatternCyclingEnabled(patternCyclingEnabled)
        overlayController.setProtectionMode(.normal)

        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    deinit {
        permissionPollTimer?.invalidate()
    }

    func toggleRequested() {
        isEnabled ? stop() : start()
    }

    func start() {
        guard AccessibilityPermissions.requestIfNeeded() else {
            accessibilityGranted = false
            lastError = "Grant Accessibility to let Drift simulate subtle pointer movement."
            return
        }

        do {
            try sleepAssertion.begin(reason: "Drift is keeping the display awake.")
            sessionStartDate = Date()
            lowRiskModeActive = false
            overlayController.setIntensity(overlayIntensity)
            overlayController.setPatternCyclingEnabled(patternCyclingEnabled)
            overlayController.setProtectionMode(.normal)
            overlayController.start()
            mouseJiggler.start()
            accessibilityGranted = true
            isEnabled = true
            lastError = nil
        } catch {
            stop(resetError: false)
            lastError = error.localizedDescription
        }
    }

    func stop(resetError: Bool = true) {
        mouseJiggler.stop()
        overlayController.stop()
        sleepAssertion.end()
        isEnabled = false
        lowRiskModeActive = false
        sessionStartDate = nil

        if resetError {
            lastError = nil
        }
    }

    func openAccessibilitySettings() {
        AccessibilityPermissions.openSystemSettings()
    }

    private func tick() {
        refreshPermissions()
        refreshProtectionProfile()
    }

    private func refreshPermissions() {
        let granted = AccessibilityPermissions.isGranted

        if granted != accessibilityGranted {
            accessibilityGranted = granted
        }

        if !granted, isEnabled {
            stop(resetError: false)
            lastError = "Accessibility permission was removed while Drift Mode was active."
        }
    }

    private func refreshProtectionProfile() {
        guard isEnabled else {
            lowRiskModeActive = false
            overlayController.setProtectionMode(.normal)
            return
        }

        guard autoLowRiskEnabled, let sessionStartDate else {
            if lowRiskModeActive {
                lowRiskModeActive = false
                overlayController.setProtectionMode(.normal)
            }
            return
        }

        let elapsed = Date().timeIntervalSince(sessionStartDate)
        let shouldElevate = elapsed >= (lowRiskDelayMinutes * 60)

        guard shouldElevate != lowRiskModeActive else { return }

        lowRiskModeActive = shouldElevate
        overlayController.setProtectionMode(shouldElevate ? .elevated : .normal)
    }
}
