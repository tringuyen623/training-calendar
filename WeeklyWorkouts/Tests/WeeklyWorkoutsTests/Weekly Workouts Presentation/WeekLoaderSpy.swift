import Foundation
import WeeklyWorkouts

@MainActor
final class WeekLoaderSpy: WeekLoader {
    private(set) var loadCallCount = 0
    private var result: Result<[WorkoutDay], Error> = .success([])
    private var isLoadPending = false
    private var pendingLoads: [CheckedContinuation<[WorkoutDay], Error>] = []
    private var pendingLoadWaiters: [CheckedContinuation<Void, Never>] = []

    func stub(days: [WorkoutDay]) {
        result = .success(days)
    }

    func stub(error: Error) {
        result = .failure(error)
    }

    /// Loads stay pending until `completePendingLoads(with:)`.
    func stubPendingLoad() {
        isLoadPending = true
    }

    func waitForPendingLoad() async {
        while pendingLoads.isEmpty {
            await withCheckedContinuation { pendingLoadWaiters.append($0) }
        }
    }

    func completePendingLoads(with days: [WorkoutDay]) {
        pendingLoads.forEach { $0.resume(returning: days) }
        pendingLoads.removeAll()
    }

    func loadWeek() async throws -> [WorkoutDay] {
        loadCallCount += 1
        if isLoadPending {
            return try await withCheckedThrowingContinuation { continuation in
                pendingLoads.append(continuation)
                pendingLoadWaiters.forEach { $0.resume() }
                pendingLoadWaiters.removeAll()
            }
        }
        return try result.get()
    }
}
