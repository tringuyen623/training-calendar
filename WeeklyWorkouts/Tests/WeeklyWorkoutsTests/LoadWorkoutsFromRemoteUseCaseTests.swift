import Foundation
import Testing
import WeeklyWorkouts

struct LoadWorkoutsFromRemoteUseCaseTests {
    @Test func init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        #expect(client.requestedURLs.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteWorkoutsLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteWorkoutsLoader(url: url, client: client)
        return (sut, client)
    }

    private final class HTTPClientSpy: HTTPClient {
        private(set) var requestedURLs: [URL] = []

        func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
            requestedURLs.append(url)
            throw NSError(domain: "not stubbed", code: 0)
        }
    }
}
