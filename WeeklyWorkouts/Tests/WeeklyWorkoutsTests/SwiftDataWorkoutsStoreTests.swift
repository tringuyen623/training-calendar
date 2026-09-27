import Foundation
import SwiftData
import Testing
import WeeklyWorkouts

/// Core Data crashes when containers for the same models are created concurrently, as parallel tests do.
private let containerCreationLock = NSLock()

struct SwiftDataWorkoutsStoreTests {
    @Test func retrieve_deliversEmptyOnEmptyCache() async throws {
        let sut = try makeSUT()

        let cache = try await sut.retrieve()

        #expect(cache == nil)
    }

    @Test func retrieve_deliversFoundValuesOnNonEmptyCache() async throws {
        let sut = try makeSUT()
        let days = daysOutOfNaturalOrder()
        let timestamp = Date(timeIntervalSince1970: 1_000)

        try await sut.insert(days, timestamp: timestamp)
        let cache = try await sut.retrieve()

        #expect(cache == CachedWorkouts(days: days, timestamp: timestamp))
    }

    @Test func retrieve_deliversCacheWithNoDaysOnCacheInsertedWithNoDays() async throws {
        let sut = try makeSUT()
        let timestamp = Date(timeIntervalSince1970: 1_000)

        try await sut.insert([], timestamp: timestamp)
        let cache = try await sut.retrieve()

        #expect(cache == CachedWorkouts(days: [], timestamp: timestamp))
    }

    @Test func retrieve_hasNoSideEffectsOnNonEmptyCache() async throws {
        let sut = try makeSUT()
        let days = daysOutOfNaturalOrder()
        let timestamp = Date(timeIntervalSince1970: 1_000)
        try await sut.insert(days, timestamp: timestamp)

        let firstCache = try await sut.retrieve()
        let secondCache = try await sut.retrieve()

        #expect(firstCache == CachedWorkouts(days: days, timestamp: timestamp))
        #expect(secondCache == firstCache)
    }

    // MARK: - Helpers

    private func makeSUT(container: ModelContainer? = nil) throws -> SwiftDataWorkoutsStore {
        SwiftDataWorkoutsStore(modelContainer: try container ?? makeContainer())
    }

    private func makeContainer() throws -> ModelContainer {
        try containerCreationLock.withLock {
            try ModelContainer(
                for: Schema(SwiftDataWorkoutsStore.models),
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
    }

    /// Saved order differs from both `day` order and ID order, so only a store keeping the saved order passes.
    private func daysOutOfNaturalOrder() -> [WorkoutDay] {
        [
            WorkoutDay(id: "day-c", day: 5, workouts: [
                Workout(id: "workout-z", title: "Legs", status: .completed, exerciseCount: 3),
                Workout(id: "workout-x", title: "Arms", status: .assigned, exerciseCount: 1),
                Workout(id: "workout-y", title: "Core", status: .missed, exerciseCount: 7),
            ]),
            WorkoutDay(id: "day-a", day: 0, workouts: []),
            WorkoutDay(id: "day-b", day: 3, workouts: [
                Workout(id: "workout-w", title: "Run", status: .assigned, exerciseCount: 2),
            ]),
        ]
    }
}
