import Foundation
import Testing
@testable import WeeklyWorkouts

private let now = date(2026, 9, 30, 12, 0)

@MainActor
struct WeeklyWorkoutsServiceTests {
    @Test func init_doesNotMessageClientOrStore() {
        let (_, client, store) = makeSUT()

        #expect(client.requestedURLs.isEmpty)
        #expect(store.receivedMessages.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!
    ) -> (sut: WeeklyWorkoutsService, client: HTTPClientSpy, store: WeeklyWorkoutsStoreSpy) {
        let client = HTTPClientSpy()
        let store = WeeklyWorkoutsStoreSpy()
        let sut = WeeklyWorkoutsService(url: url, client: client, store: store, calendar: makeCalendar(), currentDate: { now })
        return (sut, client, store)
    }
}
