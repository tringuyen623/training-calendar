import Foundation
import WeeklyWorkouts

@MainActor
final class CompletionTogglerSpy: CompletionToggler {
    struct Toggle: Equatable {
        let workoutID: String
        let isCompleted: Bool
    }

    private(set) var receivedToggles: [Toggle] = []
    private var error: Error?
    private var isTogglePending = false
    private var pendingToggle: CheckedContinuation<Bool, Error>?
    private var pendingToggleWaiters: [CheckedContinuation<Void, Never>] = []

    func stub(error: Error) {
        self.error = error
    }

    /// Toggles stay pending until `completePendingToggle(with:)`.
    func stubPendingToggle() {
        isTogglePending = true
    }

    func waitForPendingToggle() async {
        while pendingToggle == nil {
            await withCheckedContinuation { pendingToggleWaiters.append($0) }
        }
    }

    func completePendingToggle(with result: Result<Bool, Error>) {
        pendingToggle?.resume(with: result)
        pendingToggle = nil
    }

    /// Delivers the inverted completion unless stubbed with an error.
    func toggle(workoutID: String, isCompleted: Bool) async throws -> Bool {
        receivedToggles.append(Toggle(workoutID: workoutID, isCompleted: isCompleted))
        if isTogglePending {
            return try await withCheckedThrowingContinuation { continuation in
                pendingToggle = continuation
                pendingToggleWaiters.forEach { $0.resume() }
                pendingToggleWaiters.removeAll()
            }
        }
        if let error {
            throw error
        }
        return !isCompleted
    }
}
