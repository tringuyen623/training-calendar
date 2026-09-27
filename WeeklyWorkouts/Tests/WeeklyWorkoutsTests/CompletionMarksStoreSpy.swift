import Foundation
import WeeklyWorkouts

final class CompletionMarksStoreSpy: CompletionMarksStore {
    enum Message: Equatable {
        case deleteAllMarks
        case insertMark(Bool, String)
        case retrieveAllMarks
    }

    private(set) var receivedMessages: [Message] = []
    private var deletionResult: Result<Void, Error> = .success(())
    private var insertionResult: Result<Void, Error> = .success(())
    private var retrievalResult: Result<[String: Bool], Error> = .success([:])
    private var isInsertionPending = false
    private var pendingInsertion: CheckedContinuation<Void, Error>?
    private var pendingInsertionWaiters: [CheckedContinuation<Void, Never>] = []

    func stubDeletion(with error: Error) {
        deletionResult = .failure(error)
    }

    func stubInsertion(with error: Error) {
        insertionResult = .failure(error)
    }

    /// Insertions stay pending until `completePendingInsertion(with:)`.
    func stubPendingInsertion() {
        isInsertionPending = true
    }

    func waitForPendingInsertion() async {
        while pendingInsertion == nil {
            await withCheckedContinuation { pendingInsertionWaiters.append($0) }
        }
    }

    func completePendingInsertion(with result: Result<Void, Error>) {
        pendingInsertion?.resume(with: result)
        pendingInsertion = nil
    }

    func stubRetrieval(with marks: [String: Bool]) {
        retrievalResult = .success(marks)
    }

    func stubRetrieval(with error: Error) {
        retrievalResult = .failure(error)
    }

    func deleteAllMarks() async throws {
        receivedMessages.append(.deleteAllMarks)
        try deletionResult.get()
    }

    func insertMark(_ isCompleted: Bool, for workoutID: String) async throws {
        receivedMessages.append(.insertMark(isCompleted, workoutID))
        if isInsertionPending {
            return try await withCheckedThrowingContinuation { continuation in
                pendingInsertion = continuation
                pendingInsertionWaiters.forEach { $0.resume() }
                pendingInsertionWaiters.removeAll()
            }
        }
        try insertionResult.get()
    }

    func retrieveAllMarks() async throws -> [String: Bool] {
        receivedMessages.append(.retrieveAllMarks)
        return try retrievalResult.get()
    }
}
