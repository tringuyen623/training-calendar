import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession) {
        self.session = session
    }

    private struct UnexpectedResponse: Error {}

    public func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        _ = try await session.data(from: url)
        throw UnexpectedResponse()
    }
}
