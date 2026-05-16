import AppKit
import Foundation

final class MouseJiggler {
    private let queue = DispatchQueue(label: "Drift.MouseJiggler", qos: .utility)
    private var pendingWorkItem: DispatchWorkItem?
    private var isRunning = false

    func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduleNextJiggle(after: .seconds(5))
    }

    func stop() {
        isRunning = false
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
    }

    private func scheduleNextJiggle(after delay: DispatchTimeInterval) {
        pendingWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.isRunning else { return }
            self.performJiggle()
            self.scheduleNextJiggle(after: .seconds(Int.random(in: 45 ... 90)))
        }

        pendingWorkItem = workItem
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func performJiggle() {
        let currentLocation = NSEvent.mouseLocation
        let deltaX = CGFloat.random(in: -2 ... 2).rounded(.towardZero)
        let deltaY = CGFloat.random(in: -1 ... 1).rounded(.towardZero)

        guard deltaX != 0 || deltaY != 0 else {
            performJiggle()
            return
        }

        let shiftedLocation = CGPoint(x: currentLocation.x + deltaX, y: currentLocation.y + deltaY)

        postMouseMove(at: shiftedLocation)
        queue.asyncAfter(deadline: .now() + .milliseconds(140)) {
            self.postMouseMove(at: currentLocation)
        }
    }

    private func postMouseMove(at point: CGPoint) {
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            return
        }

        event.post(tap: .cghidEventTap)
    }
}
