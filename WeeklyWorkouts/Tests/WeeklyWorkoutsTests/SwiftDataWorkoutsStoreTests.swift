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

    @Test func retrieve_deliversCacheInsertedByAnotherInstance() async throws {
        let container = try makeContainer()
        let sutToInsert = try makeSUT(container: container)
        let sutToRetrieve = try makeSUT(container: container)
        let days = daysOutOfNaturalOrder()
        let timestamp = Date(timeIntervalSince1970: 1_000)

        try await sutToInsert.insert(days, timestamp: timestamp)
        let cache = try await sutToRetrieve.retrieve()

        #expect(cache == CachedWorkouts(days: days, timestamp: timestamp))
    }

    @Test func insert_overridesPreviouslyInsertedCache() async throws {
        let sut = try makeSUT()
        try await sut.insert(daysOutOfNaturalOrder(), timestamp: Date(timeIntervalSince1970: 1_000))
        let latestDays = [
            WorkoutDay(id: "day-latest", day: 2, workouts: [
                Workout(id: "workout-latest", title: "Swim", status: .missed, exerciseCount: 4),
            ]),
        ]
        let latestTimestamp = Date(timeIntervalSince1970: 2_000)

        try await sut.insert(latestDays, timestamp: latestTimestamp)
        let cache = try await sut.retrieve()

        #expect(cache == CachedWorkouts(days: latestDays, timestamp: latestTimestamp))
    }

    @Test func insert_doesNotDeleteOtherModelsInTheSameContainer() async throws {
        let container = try makeContainer()
        let sut = try makeSUT(container: container)
        try await sut.insert(daysOutOfNaturalOrder(), timestamp: Date(timeIntervalSince1970: 1_000))
        try insertOtherModel(into: container)

        try await sut.insert(daysOutOfNaturalOrder(), timestamp: Date(timeIntervalSince1970: 2_000))

        #expect(try otherModelsCount(in: container) == 1)
    }

    @Test func delete_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = try makeSUT()

        try await sut.deleteCachedWorkouts()
        let cache = try await sut.retrieve()

        #expect(cache == nil)
    }

    @Test func delete_emptiesPreviouslyInsertedCache() async throws {
        let sut = try makeSUT()
        try await sut.insert(daysOutOfNaturalOrder(), timestamp: Date(timeIntervalSince1970: 1_000))

        try await sut.deleteCachedWorkouts()
        let cache = try await sut.retrieve()

        #expect(cache == nil)
    }

    @Test func delete_emptiesCacheForAnotherInstance() async throws {
        let container = try makeContainer()
        let sutToDelete = try makeSUT(container: container)
        let sutToRetrieve = try makeSUT(container: container)
        try await sutToDelete.insert(daysOutOfNaturalOrder(), timestamp: Date(timeIntervalSince1970: 1_000))

        try await sutToDelete.deleteCachedWorkouts()
        let cache = try await sutToRetrieve.retrieve()

        #expect(cache == nil)
    }

    @Test func delete_doesNotDeleteOtherModelsInTheSameContainer() async throws {
        let container = try makeContainer()
        let sut = try makeSUT(container: container)
        try await sut.insert(daysOutOfNaturalOrder(), timestamp: Date(timeIntervalSince1970: 1_000))
        try insertOtherModel(into: container)

        try await sut.deleteCachedWorkouts()

        #expect(try otherModelsCount(in: container) == 1)
    }

    @Test func retrieveAllMarks_deliversNoMarksOnEmptyStore() async throws {
        let sut = try makeSUT()

        let marks = try await sut.retrieveAllMarks()

        #expect(marks.isEmpty)
    }

    @Test func retrieveAllMarks_deliversInsertedMarksKeyedByWorkoutID() async throws {
        let sut = try makeSUT()

        try await sut.insertMark(true, for: "workout-a")
        try await sut.insertMark(false, for: "workout-b")
        let marks = try await sut.retrieveAllMarks()

        #expect(marks == ["workout-a": true, "workout-b": false])
    }

    @Test func insertMark_replacesPreviousMarkForTheSameWorkoutID() async throws {
        let sut = try makeSUT()
        try await sut.insertMark(true, for: "workout-a")

        try await sut.insertMark(false, for: "workout-a")
        let marks = try await sut.retrieveAllMarks()

        #expect(marks == ["workout-a": false])
    }

    // MARK: - Helpers

    private func makeSUT(container: ModelContainer? = nil) throws -> SwiftDataWorkoutsStore {
        SwiftDataWorkoutsStore(modelContainer: try container ?? makeContainer())
    }

    private func makeContainer() throws -> ModelContainer {
        try containerCreationLock.withLock {
            try ModelContainer(
                for: Schema(SwiftDataWorkoutsStore.models + [OtherModel.self]),
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
    }

    private func insertOtherModel(into container: ModelContainer) throws {
        let context = ModelContext(container)
        context.insert(OtherModel())
        try context.save()
    }

    private func otherModelsCount(in container: ModelContainer) throws -> Int {
        try ModelContext(container).fetchCount(FetchDescriptor<OtherModel>())
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

/// Stands for any other model sharing the container, such as the completion marks.
@Model
private final class OtherModel {
    var createdAt = Date(timeIntervalSince1970: 0)

    init() {}
}
