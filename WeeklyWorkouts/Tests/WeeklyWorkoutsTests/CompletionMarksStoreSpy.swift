import Foundation
import WeeklyWorkouts

final class CompletionMarksStoreSpy: CompletionMarksStore {
    enum Message: Equatable {
        case deleteAllMarks
        case insertMark(Bool, String)
    }

    private(set) var receivedMessages: [Message] = []
    private var deletionResult: Result<Void, Error> = .success(())

    func stubDeletion(with error: Error) {
        deletionResult = .failure(error)
    }

    func deleteAllMarks() async throws {
        receivedMessages.append(.deleteAllMarks)
        try deletionResult.get()
    }

    func insertMark(_ isCompleted: Bool, for workoutID: String) async throws {
        receivedMessages.append(.insertMark(isCompleted, workoutID))
    }
}
