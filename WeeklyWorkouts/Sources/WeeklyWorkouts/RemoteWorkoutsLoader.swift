import Foundation

public final class RemoteWorkoutsLoader: WorkoutsLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error, Equatable {
        case connectivity
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
        } catch {
            throw Error.connectivity
        }

        do {
            return try WorkoutDaysMapper.map(data, from: response)
        } catch {
            throw Error.invalidData
        }
    }
}
