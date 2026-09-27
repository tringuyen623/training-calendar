import Foundation
import Testing
import WeeklyWorkouts

struct LoadWorkoutsFromRemoteUseCaseTests {
    @Test func init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        #expect(client.requestedURLs.isEmpty)
    }

    @Test func load_requestsDataFromURL() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        _ = try? await sut.load()

        #expect(client.requestedURLs == [url])
    }

    @Test func loadTwice_requestsDataFromURLTwice() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        _ = try? await sut.load()
        _ = try? await sut.load()

        #expect(client.requestedURLs == [url, url])
    }

    @Test func load_deliversConnectivityErrorOnClientError() async {
        let (sut, client) = makeSUT()
        client.result = .failure(anyNSError())

        await #expect(throws: RemoteWorkoutsLoader.Error.connectivity) {
            try await sut.load()
        }
    }

    @Test(arguments: [199, 201, 300, 400, 500])
    func load_deliversInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) async {
        let (sut, client) = makeSUT()
        client.result = .success((makeJSON(days: []), HTTPURLResponse(statusCode: statusCode)))

        await #expect(throws: RemoteWorkoutsLoader.Error.invalidData) {
            try await sut.load()
        }
    }

    @Test func load_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() async {
        let (sut, client) = makeSUT()
        client.result = .success((Data("invalid json".utf8), HTTPURLResponse(statusCode: 200)))

        await #expect(throws: RemoteWorkoutsLoader.Error.invalidData) {
            try await sut.load()
        }
    }

    @Test(arguments: ["_id", "day", "assignments"])
    func load_deliversInvalidDataErrorOn200HTTPResponseWithDayMissingField(field: String) async {
        let (sut, client) = makeSUT()
        var day = makeDayJSON(workouts: [makeWorkoutJSON()])
        day[field] = nil
        client.result = .success((makeJSON(days: [day]), HTTPURLResponse(statusCode: 200)))

        await #expect(throws: RemoteWorkoutsLoader.Error.invalidData) {
            try await sut.load()
        }
    }

    @Test(arguments: ["_id", "title", "status", "total_exercise"])
    func load_deliversInvalidDataErrorOn200HTTPResponseWithWorkoutMissingField(field: String) async {
        let (sut, client) = makeSUT()
        var workout = makeWorkoutJSON()
        workout[field] = nil
        client.result = .success((makeJSON(days: [makeDayJSON(workouts: [workout])]), HTTPURLResponse(statusCode: 200)))

        await #expect(throws: RemoteWorkoutsLoader.Error.invalidData) {
            try await sut.load()
        }
    }

    @Test(arguments: [-1, 3])
    func load_deliversInvalidDataErrorOn200HTTPResponseWithUnknownStatus(status: Int) async {
        let (sut, client) = makeSUT()
        let day = makeDayJSON(workouts: [makeWorkoutJSON(status: status)])
        client.result = .success((makeJSON(days: [day]), HTTPURLResponse(statusCode: 200)))

        await #expect(throws: RemoteWorkoutsLoader.Error.invalidData) {
            try await sut.load()
        }
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteWorkoutsLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteWorkoutsLoader(url: url, client: client)
        return (sut, client)
    }

    private func makeJSON(days: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: ["data": days])
    }

    private func makeDayJSON(id: String = "any-day-id", day: Int = 0, workouts: [[String: Any]] = []) -> [String: Any] {
        ["_id": id, "day": day, "assignments": workouts]
    }

    private func makeWorkoutJSON(id: String = "any-workout-id", title: String = "any title", status: Int = 0, exerciseCount: Int = 1) -> [String: Any] {
        ["_id": id, "title": title, "status": status, "total_exercise": exerciseCount]
    }

    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }

    private final class HTTPClientSpy: HTTPClient {
        private(set) var requestedURLs: [URL] = []
        var result: Result<(Data, HTTPURLResponse), Error> = .failure(NSError(domain: "not stubbed", code: 0))

        func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
            requestedURLs.append(url)
            return try result.get()
        }
    }
}

private extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: URL(string: "https://any-url.com")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
