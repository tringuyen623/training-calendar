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

    @Test func load_deliversRequestFailureErrorOnClientError() async {
        let (sut, client) = makeSUT()
        client.stub(error: anyNSError())

        await #expect(throws: RemoteWorkoutsLoader.Error.requestFailure) {
            try await sut.load()
        }
    }

    @Test func load_deliversCancellationErrorOnClientCancellation() async {
        let (sut, client) = makeSUT()
        client.stub(error: CancellationError())

        await #expect(throws: CancellationError.self) {
            try await sut.load()
        }
    }

    @Test func load_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() async {
        let (sut, client) = makeSUT()
        client.stub(statusCode: 200, data: Data("invalid json".utf8))

        await #expect(throws: RemoteWorkoutsLoader.Error.invalidData) {
            try await sut.load()
        }
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
        client.stub(statusCode: 200, data: json)

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
}
