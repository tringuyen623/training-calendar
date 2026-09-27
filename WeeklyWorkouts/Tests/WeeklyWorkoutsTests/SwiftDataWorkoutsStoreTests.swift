import Foundation
import SwiftData
import Testing
import WeeklyWorkouts

struct SwiftDataWorkoutsStoreTests {
    @Test func retrieve_deliversEmptyOnEmptyCache() async throws {
        let sut = try makeSUT()

        let cache = try await sut.retrieve()

        #expect(cache == nil)
    }

    // MARK: - Helpers

    private func makeSUT(container: ModelContainer? = nil) throws -> SwiftDataWorkoutsStore {
        SwiftDataWorkoutsStore(modelContainer: try container ?? makeContainer())
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(SwiftDataWorkoutsStore.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
