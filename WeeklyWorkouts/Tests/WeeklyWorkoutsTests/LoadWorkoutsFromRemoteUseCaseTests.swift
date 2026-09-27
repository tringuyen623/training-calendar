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

    @Test func load_deliversCancellationErrorOnClientCancellation() async {
        let (sut, client) = makeSUT()
        client.result = .failure(CancellationError())

        await #expect(throws: CancellationError.self) {
            try await sut.load()
        }
    }

    @Test(arguments: [199, 201, 300, 400, 500])
    func load_deliversInvalidDataErrorOnNon200HTTPResponse(statusCode: Int) async {
        let (sut, client) = makeSUT()
        client.complete(withStatusCode: statusCode, data: makeJSON(days: []))

        await #expect(throws: RemoteWorkoutsLoader.Error.invalidData) {
            try await sut.load()
        }
    }

    @Test func load_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() async {
        let (sut, client) = makeSUT()
        client.complete(withStatusCode: 200, data: Data("invalid json".utf8))

        await #expect(throws: RemoteWorkoutsLoader.Error.invalidData) {
            try await sut.load()
        }
    }

    @Test(arguments: ["_id", "day", "assignments"])
    func load_deliversInvalidDataErrorOn200HTTPResponseWithDayMissingField(field: String) async {
        let (sut, client) = makeSUT()
        var day = makeDayJSON(workouts: [makeWorkoutJSON()])
        day[field] = nil
        client.complete(withStatusCode: 200, data: makeJSON(days: [day]))

        await #expect(throws: RemoteWorkoutsLoader.Error.invalidData) {
            try await sut.load()
        }
    }

    @Test(arguments: ["_id", "title", "status", "total_exercise"])
    func load_deliversInvalidDataErrorOn200HTTPResponseWithWorkoutMissingField(field: String) async {
        let (sut, client) = makeSUT()
        var workout = makeWorkoutJSON()
        workout[field] = nil
        client.complete(withStatusCode: 200, data: makeJSON(days: [makeDayJSON(workouts: [workout])]))

        await #expect(throws: RemoteWorkoutsLoader.Error.invalidData) {
            try await sut.load()
        }
    }

    @Test(arguments: [-1, 3])
    func load_deliversInvalidDataErrorOn200HTTPResponseWithUnknownStatus(status: Int) async {
        let (sut, client) = makeSUT()
        let day = makeDayJSON(workouts: [makeWorkoutJSON(status: status)])
        client.complete(withStatusCode: 200, data: makeJSON(days: [day]))

        await #expect(throws: RemoteWorkoutsLoader.Error.invalidData) {
            try await sut.load()
        }
    }

    @Test(arguments: [-1, 7])
    func load_deliversInvalidDataErrorOn200HTTPResponseWithDayOutOfRange(day: Int) async {
        let (sut, client) = makeSUT()
        client.complete(withStatusCode: 200, data: makeJSON(days: [makeDayJSON(day: day)]))

        await #expect(throws: RemoteWorkoutsLoader.Error.invalidData) {
            try await sut.load()
        }
    }

    @Test func load_deliversNoDaysOn200HTTPResponseWithEmptyJSONList() async throws {
        let (sut, client) = makeSUT()
        client.complete(withStatusCode: 200, data: makeJSON(days: []))

        let days = try await sut.load()

        #expect(days.isEmpty)
    }

    @Test func load_deliversMappedDaysOn200HTTPResponseWithJSONDays() async throws {
        let (sut, client) = makeSUT()
        let json = makeJSON(days: [
            makeDayJSON(id: "day-3", day: 3, workouts: [
                makeWorkoutJSON(id: "w-completed", title: "Legs day", status: 2, exerciseCount: 5),
            ]),
            makeDayJSON(id: "day-0", day: 0, workouts: [
                makeWorkoutJSON(id: "w-assigned", title: "Full warm up workout", status: 0, exerciseCount: 6),
                makeWorkoutJSON(id: "w-missed", title: "HIIT Tabata 20:10 8x8", status: 1, exerciseCount: 15),
            ]),
            makeDayJSON(id: "day-5", day: 5, workouts: []),
        ])
        client.complete(withStatusCode: 200, data: json)

        let days = try await sut.load()

        #expect(days == [
            WorkoutDay(id: "day-3", day: 3, workouts: [
                Workout(id: "w-completed", title: "Legs day", status: .completed, exerciseCount: 5),
            ]),
            WorkoutDay(id: "day-0", day: 0, workouts: [
                Workout(id: "w-assigned", title: "Full warm up workout", status: .assigned, exerciseCount: 6),
                Workout(id: "w-missed", title: "HIIT Tabata 20:10 8x8", status: .missed, exerciseCount: 15),
            ]),
            WorkoutDay(id: "day-5", day: 5, workouts: []),
        ])
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

        func complete(withStatusCode code: Int, data: Data) {
            result = .success((data, HTTPURLResponse(statusCode: code)))
        }

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
