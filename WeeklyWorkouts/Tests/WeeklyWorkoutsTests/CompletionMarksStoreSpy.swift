import Foundation
import WeeklyWorkouts

final class CompletionMarksStoreSpy: CompletionMarksStore {
    enum Message: Equatable {
        case deleteAllMarks
    }

    private(set) var receivedMessages: [Message] = []

    func deleteAllMarks() async throws {
        receivedMessages.append(.deleteAllMarks)
    }
}
