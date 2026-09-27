import Foundation
import WeeklyWorkouts

final class WorkoutsStoreSpy: WorkoutsStore {
    enum Message: Equatable {
        case retrieve
        case deleteCachedWorkouts
    }

    private(set) var receivedMessages: [Message] = []
    private var retrievalResult: Result<CachedWorkouts?, Error> = .success(nil)
    private var deletionResult: Result<Void, Error> = .success(())

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

    func retrieve() async throws -> CachedWorkouts? {
        receivedMessages.append(.retrieve)
        return try retrievalResult.get()
    }

    func deleteCachedWorkouts() async throws {
        receivedMessages.append(.deleteCachedWorkouts)
        try deletionResult.get()
    }
}
