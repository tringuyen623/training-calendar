import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession) {
        self.session = session
    }

    private struct UnexpectedResponse: Error {}

    public func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await load(from: url)
        guard let response = response as? HTTPURLResponse else {
            throw UnexpectedResponse()
        }
        return (data, response)
    }

    private func load(from url: URL) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(from: url)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        }
    }
}
