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
        let (data, response): (Data, HTTPURLResponse)
        do {
            (data, response) = try await client.get(from: url)
        } catch let cancellation as CancellationError {
            throw cancellation
        } catch {
            throw Error.requestFailure
        }

        do {
            return try WorkoutDaysMapper.map(data, from: response)
        } catch {
            throw Error.invalidData
        }
    }
}
