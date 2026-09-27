import Foundation

public final class RemoteWorkoutsLoader: WorkoutsLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error, Equatable {
        case requestFailure
        case invalidData
    }

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load() async throws -> [WorkoutDay] {
        let (data, response) = try await fetch()
        return try map(data, from: response)
    }

    private func fetch() async throws -> (Data, HTTPURLResponse) {
        do {
            return try await client.get(from: url)
        } catch let cancellation as CancellationError {
            throw cancellation
        } catch {
            throw Error.requestFailure
        }
    }

    private func map(_ data: Data, from response: HTTPURLResponse) throws -> [WorkoutDay] {
        do {
            return try WorkoutDaysMapper.map(data, from: response)
        } catch {
            throw Error.invalidData
        }
    }
}
