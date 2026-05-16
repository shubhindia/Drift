import Foundation
import IOKit.pwr_mgt

enum SleepAssertionError: LocalizedError {
    case creationFailed(IOReturn)

    var errorDescription: String? {
        switch self {
        case .creationFailed(let code):
            return "Unable to create a power assertion (IOReturn \(code))."
        }
    }
}

final class SleepAssertion {
    private var displayAssertionID: IOPMAssertionID = 0
    private var systemAssertionID: IOPMAssertionID = 0

    var isActive: Bool {
        displayAssertionID != 0 || systemAssertionID != 0
    }

    func begin(reason: String) throws {
        guard !isActive else { return }

        let displayResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &displayAssertionID
        )

        guard displayResult == kIOReturnSuccess else {
            throw SleepAssertionError.creationFailed(displayResult)
        }

        let systemResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &systemAssertionID
        )

        guard systemResult == kIOReturnSuccess else {
            end()
            throw SleepAssertionError.creationFailed(systemResult)
        }
    }

    func end() {
        if displayAssertionID != 0 {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = 0
        }

        if systemAssertionID != 0 {
            IOPMAssertionRelease(systemAssertionID)
            systemAssertionID = 0
        }
    }
}
