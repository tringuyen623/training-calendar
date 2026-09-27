import Foundation

public final class RemoteWorkoutsLoader {
    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load() async throws -> [WorkoutDay] {
        _ = try await client.get(from: url)
        return []
    }
}
