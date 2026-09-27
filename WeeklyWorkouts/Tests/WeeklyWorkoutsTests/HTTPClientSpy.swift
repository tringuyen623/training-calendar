import Foundation
import WeeklyWorkouts

final class HTTPClientSpy: HTTPClient {
    private(set) var requestedURLs: [URL] = []
    private var result: Result<(Data, HTTPURLResponse), Error> = .failure(NSError(domain: "not stubbed", code: 0))
    private var isRequestPending = false
    private var pendingRequest: CheckedContinuation<(Data, HTTPURLResponse), Error>?
    private var pendingRequestWaiters: [CheckedContinuation<Void, Never>] = []

    func stub(error: Error) {
        result = .failure(error)
    }

    func stub(statusCode: Int, data: Data) {
        result = .success((data, HTTPURLResponse(statusCode: statusCode)))
    }

    /// Requests stay pending until `completePendingRequest(with:)`.
    func stubPendingRequest() {
        isRequestPending = true
    }

    func waitForPendingRequest() async {
        while pendingRequest == nil {
            await withCheckedContinuation { pendingRequestWaiters.append($0) }
        }
    }

    func completePendingRequest(with error: Error) {
        pendingRequest?.resume(throwing: error)
        pendingRequest = nil
    }

    func completePendingRequest(withStatusCode statusCode: Int, data: Data) {
        pendingRequest?.resume(returning: (data, HTTPURLResponse(statusCode: statusCode)))
        pendingRequest = nil
    }

    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        requestedURLs.append(url)
        if isRequestPending {
            return try await withCheckedThrowingContinuation { continuation in
                pendingRequest = continuation
                pendingRequestWaiters.forEach { $0.resume() }
                pendingRequestWaiters.removeAll()
            }
        }
        return try result.get()
    }
}

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: URL(string: "https://any-url.com")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
