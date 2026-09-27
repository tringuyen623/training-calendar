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

    // MARK: - Helpers

    private func makeSUT() -> (sut: LocalWorkoutsLoader, store: WorkoutsStoreSpy) {
        let store = WorkoutsStoreSpy()
        let sut = LocalWorkoutsLoader(store: store)
        return (sut, store)
    }

    private final class WorkoutsStoreSpy: WorkoutsStore {
        enum Message: Equatable {
            case retrieve
        }

        private(set) var receivedMessages: [Message] = []

        func retrieve() async throws -> CachedWorkouts? {
            receivedMessages.append(.retrieve)
            return nil
        }
    }
}
