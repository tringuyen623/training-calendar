import Foundation

public typealias WeeklyWorkoutsStore = WorkoutsStore & CompletionMarksStore

@MainActor
public final class WeeklyWorkoutsService {
    private let url: URL
    private let client: HTTPClient
    private let store: WeeklyWorkoutsStore
    private let local: LocalWorkoutsLoader

    public enum Error: Swift.Error, Equatable {
        case requestFailure
        case invalidData
    }

    public init(url: URL, client: HTTPClient, store: WeeklyWorkoutsStore, calendar: Calendar, currentDate: @escaping () -> Date) {
        self.url = url
        self.client = client
        self.store = store
        self.local = LocalWorkoutsLoader(store: store, marksStore: store, calendar: calendar, currentDate: currentDate)
    }

    public func loadWeek() async throws -> [WorkoutDay] {
        let (data, response) = try await fetch()
        let days = try map(data, from: response)
        // The loaded week is still delivered when saving fails: the next load saves it again.
        try? await local.save(days)
        return days
    }

    public func loadCachedWeek() async throws -> [WorkoutDay] {
        let days = try await local.load()
        let marks = try await store.retrieveAllMarks()
        return applying(marks, to: days)
    }

    // Generated with Claude. Adjusted to handle a "not completed" mark on a workout the server reports as completed.
    // Marks are looked up by workout ID, so marks for workouts not in the week are never used.
    private func applying(_ marks: [String: Bool], to days: [WorkoutDay]) -> [WorkoutDay] {
        days.map { day in
            WorkoutDay(id: day.id, day: day.day, workouts: day.workouts.map { workout in
                guard let isCompleted = marks[workout.id] else { return workout }
                return Workout(
                    id: workout.id,
                    title: workout.title,
                    status: isCompleted ? .completed : .assigned,
                    exerciseCount: workout.exerciseCount
                )
            })
        }
    }

    private func fetch()async throws -> (Data, HTTPURLResponse) {
        do {
            return try await client.get(from: url)
        } catch let cancellation as CancellationError {
            throw cancellation
        } catch {
            throw Error.requestFailure
        }
    }

    private func map(_ data: Data, from response: HTTPURLResponse) throws -> [WorkoutDay] {
        do {
            return try WorkoutDaysMapper.map(data, from: response)
        } catch {
            throw Error.invalidData
        }
    }
}
