import Foundation
import WeeklyWorkouts

final class HTTPClientSpy: HTTPClient {
    private(set) var requestedURLs: [URL] = []
    private var result: Result<(Data, HTTPURLResponse), Error> = .failure(NSError(domain: "not stubbed", code: 0))
    private var isRequestPending = false
    private var pendingRequests: [CheckedContinuation<(Data, HTTPURLResponse), Error>] = []
    private var pendingRequestWaiters: [CheckedContinuation<Void, Never>] = []

    func stub(error: Error) {
        result = .failure(error)
    }

    func stub(statusCode: Int, data: Data) {
        result = .success((data, HTTPURLResponse(statusCode: statusCode)))
    }

    /// Requests stay pending until `completePendingRequests(with:)` or `completePendingRequests(withStatusCode:data:)`.
    func stubPendingRequest() {
        isRequestPending = true
    }

    func waitForPendingRequest() async {
        while pendingRequests.isEmpty {
            await withCheckedContinuation { pendingRequestWaiters.append($0) }
        }
    }

    func completePendingRequests(with error: Error) {
        pendingRequests.forEach { $0.resume(throwing: error) }
        pendingRequests.removeAll()
    }

    func completePendingRequests(withStatusCode statusCode: Int, data: Data) {
        pendingRequests.forEach { $0.resume(returning: (data, HTTPURLResponse(statusCode: statusCode))) }
        pendingRequests.removeAll()
    }

    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        requestedURLs.append(url)
        if isRequestPending {
            return try await withCheckedThrowingContinuation { continuation in
                pendingRequests.append(continuation)
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
