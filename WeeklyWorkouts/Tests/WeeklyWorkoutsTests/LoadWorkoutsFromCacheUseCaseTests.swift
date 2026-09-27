import Foundation
import Testing
import WeeklyWorkouts

struct LoadWorkoutsFromCacheUseCaseTests {
    @Test func init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        #expect(store.receivedMessages.isEmpty)
    }

    @Test func load_requestsCacheRetrieval() async {
        let (sut, store) = makeSUT()

        _ = try? await sut.load()

        #expect(store.receivedMessages == [.retrieve])
    }

    @Test func loadTwice_requestsCacheRetrievalTwice() async {
        let (sut, store) = makeSUT()

        _ = try? await sut.load()
        _ = try? await sut.load()

        #expect(store.receivedMessages == [.retrieve, .retrieve])
    }

    @Test func load_failsOnRetrievalError() async {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        store.stubRetrieval(with: retrievalError)

        await #expect {
            try await sut.load()
        } throws: { error in
            error as NSError == retrievalError
        }
    }

    @Test func load_deliversNoWorkoutsOnEmptyCache() async throws {
        let (sut, store) = makeSUT()
        store.stubEmptyCache()

        let days = try await sut.load()

        #expect(days.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: LocalWorkoutsLoader, store: WorkoutsStoreSpy) {
        let store = WorkoutsStoreSpy()
        let sut = LocalWorkoutsLoader(store: store)
        return (sut, store)
    }

    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }

    private final class WorkoutsStoreSpy: WorkoutsStore {
        enum Message: Equatable {
            case retrieve
        }

        private(set) var receivedMessages: [Message] = []
        private var retrievalResult: Result<CachedWorkouts?, Error> = .success(nil)

        func stubEmptyCache() {
            retrievalResult = .success(nil)
        }

        func stubRetrieval(with error: Error) {
            retrievalResult = .failure(error)
        }

        func retrieve() async throws -> CachedWorkouts? {
            receivedMessages.append(.retrieve)
            return try retrievalResult.get()
        }
    }
}
