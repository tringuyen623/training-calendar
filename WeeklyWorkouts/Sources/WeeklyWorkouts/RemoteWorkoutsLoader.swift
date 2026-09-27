import Foundation

public final class RemoteWorkoutsLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error, Equatable {
        case connectivity
    }

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load() async throws -> [WorkoutDay] {
        do {
            _ = try await client.get(from: url)
        } catch {
            throw Error.connectivity
        }
        return []
    }
}
