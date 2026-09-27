import Foundation
import WeeklyWorkouts

/// Spies on both the cached workouts and the completion marks, as one store holds both in the app.
final class WeeklyWorkoutsStoreSpy: WorkoutsStore, CompletionMarksStore {
    enum Message: Equatable {
        case retrieve
        case deleteCachedWorkouts
        case insert([LocalWorkoutDay], Date)
        case deleteAllMarks
        case insertMark(Bool, String)
        case retrieveAllMarks
    }

    private(set) var receivedMessages: [Message] = []

    // MARK: - Cached workouts

    private var retrievalResult: Result<CachedWorkouts?, Error> = .success(nil)
    private var deletionResult: Result<Void, Error> = .success(())
    private var insertionResult: Result<Void, Error> = .success(())

    func stubEmptyCache() {
        retrievalResult = .success(nil)
    }

    func stubRetrieval(with cache: CachedWorkouts) {
        retrievalResult = .success(cache)
    }

    func stubRetrieval(with error: Error) {
        retrievalResult = .failure(error)
    }

    func stubDeletion(with error: Error) {
        deletionResult = .failure(error)
    }

    func stubInsertion(with error: Error) {
        insertionResult = .failure(error)
    }

    func retrieve() async throws -> CachedWorkouts? {
        receivedMessages.append(.retrieve)
        return try retrievalResult.get()
    }

    func deleteCachedWorkouts() async throws {
        receivedMessages.append(.deleteCachedWorkouts)
        try deletionResult.get()
    }

    func insert(_ days: [LocalWorkoutDay], timestamp: Date) async throws {
        receivedMessages.append(.insert(days, timestamp))
        try insertionResult.get()
    }

    func changes() async -> AsyncStream<Void> {
        AsyncStream { _ in }
    }

    // MARK: - Completion marks

    private var marksDeletionResult: Result<Void, Error> = .success(())
    private var markInsertionResult: Result<Void, Error> = .success(())
    private var marksRetrievalResult: Result<[String: Bool], Error> = .success([:])
    private var isMarkInsertionPending = false
    private var pendingMarkInsertion: CheckedContinuation<Void, Error>?
    private var pendingMarkInsertionWaiters: [CheckedContinuation<Void, Never>] = []

    func stubMarksDeletion(with error: Error) {
        marksDeletionResult = .failure(error)
    }

    func stubMarkInsertion(with error: Error) {
        markInsertionResult = .failure(error)
    }

    /// Mark insertions stay pending until `completePendingMarkInsertion(with:)`.
    func stubPendingMarkInsertion() {
        isMarkInsertionPending = true
    }

    func waitForPendingMarkInsertion() async {
        while pendingMarkInsertion == nil {
            await withCheckedContinuation { pendingMarkInsertionWaiters.append($0) }
        }
    }

    func completePendingMarkInsertion(with result: Result<Void, Error>) {
        pendingMarkInsertion?.resume(with: result)
        pendingMarkInsertion = nil
    }

    func stubMarksRetrieval(with marks: [String: Bool]) {
        marksRetrievalResult = .success(marks)
    }

    func stubMarksRetrieval(with error: Error) {
        marksRetrievalResult = .failure(error)
    }

    func deleteAllMarks() async throws {
        receivedMessages.append(.deleteAllMarks)
        try marksDeletionResult.get()
    }

    func insertMark(_ isCompleted: Bool, for workoutID: String) async throws {
        receivedMessages.append(.insertMark(isCompleted, workoutID))
        if isMarkInsertionPending {
            return try await withCheckedThrowingContinuation { continuation in
                pendingMarkInsertion = continuation
                pendingMarkInsertionWaiters.forEach { $0.resume() }
                pendingMarkInsertionWaiters.removeAll()
            }
        }
        try markInsertionResult.get()
    }

    func retrieveAllMarks() async throws -> [String: Bool] {
        receivedMessages.append(.retrieveAllMarks)
        return try marksRetrievalResult.get()
    }
}
