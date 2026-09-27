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

    func stubDeletion(with error: Error) {
        deletionResult = .failure(error)
    }

    func stubInsertion(with error: Error) {
        insertionResult = .failure(error)
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
        try insertionResult.get()
    }

    func retrieveAllMarks() async throws -> [String: Bool] {
        receivedMessages.append(.retrieveAllMarks)
        return try retrievalResult.get()
    }
}
