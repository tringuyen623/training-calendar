import Foundation
import os
import Testing
import WeeklyWorkouts

@Suite(.serialized)
struct URLSessionHTTPClientTests {
    init() {
        URLProtocolStub.reset()
    }

    @Test func get_performsGETRequestWithURL() async {
        let url = URL(string: "https://a-given-url.com")!
        let sut = makeSUT()
        URLProtocolStub.stub(error: anyNSError())

        _ = try? await sut.get(from: url)

        let requests = URLProtocolStub.observedRequests
        #expect(requests.map(\.url) == [url])
        #expect(requests.map(\.httpMethod) == ["GET"])
    }

    // MARK: - Helpers

    private func makeSUT(configuration: URLSessionConfiguration = .ephemeral) -> URLSessionHTTPClient {
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        return URLSessionHTTPClient(session: session)
    }

    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }

    private final class URLProtocolStub: URLProtocol {
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        private struct State {
            var stub: Stub?
            var observedRequests: [URLRequest] = []
        }

        private static let state = OSAllocatedUnfairLock(initialState: State())

        static var observedRequests: [URLRequest] {
            state.withLock { $0.observedRequests }
        }

        static func stub(error: Error) {
            state.withLock { $0.stub = Stub(data: nil, response: nil, error: error) }
        }

        static func reset() {
            state.withLock { $0 = State() }
        }

        override class func canInit(with request: URLRequest) -> Bool {
            true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            let request = request
            let stub = Self.state.withLock { state in
                state.observedRequests.append(request)
                return state.stub
            }

            if let response = stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let data = stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let error = stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }

        override func stopLoading() {}
    }
}
