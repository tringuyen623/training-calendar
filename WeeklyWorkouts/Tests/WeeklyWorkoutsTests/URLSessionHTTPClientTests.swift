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

    @Test func get_defersCachePolicyToSessionConfiguration() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        let sut = makeSUT(configuration: configuration)
        URLProtocolStub.stub(error: anyNSError())

        _ = try? await sut.get(from: anyURL())

        #expect(URLProtocolStub.observedRequests.map(\.cachePolicy) == [.useProtocolCachePolicy])
    }

    @Test func get_failsOnRequestError() async {
        let requestError = anyNSError()
        let sut = makeSUT()
        URLProtocolStub.stub(error: requestError)

        do {
            _ = try await sut.get(from: anyURL())
            Issue.record("Expected an error, got a result instead")
        } catch let error as NSError {
            #expect(error.domain == requestError.domain)
            #expect(error.code == requestError.code)
        }
    }

    @Test func get_failsOnNonHTTPURLResponse() async {
        let url = anyURL()
        let sut = makeSUT()
        let nonHTTPResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        URLProtocolStub.stub(data: anyData(), response: nonHTTPResponse)

        await #expect(throws: (any Error).self) {
            try await sut.get(from: url)
        }
    }

    @Test func get_deliversDataAndResponseOnHTTPURLResponseWithData() async throws {
        let url = anyURL()
        let data = anyData()
        let sut = makeSUT()
        URLProtocolStub.stub(data: data, response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!)

        let (receivedData, receivedResponse) = try await sut.get(from: url)

        #expect(receivedData == data)
        #expect(receivedResponse.url == url)
        #expect(receivedResponse.statusCode == 200)
    }

    @Test func get_deliversEmptyDataAndResponseOnHTTPURLResponseWithNoData() async throws {
        let url = anyURL()
        let sut = makeSUT()
        URLProtocolStub.stub(data: nil, response: HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil)!)

        let (receivedData, receivedResponse) = try await sut.get(from: url)

        #expect(receivedData == Data())
        #expect(receivedResponse.url == url)
        #expect(receivedResponse.statusCode == 204)
    }

    @Test func get_throwsCancellationErrorOnCancelledTask() async {
        let sut = makeSUT()
        let (loadingStarted, loadingStartedContinuation) = AsyncStream.makeStream(of: Void.self)
        URLProtocolStub.stubNeverCompleting { loadingStartedContinuation.yield() }

        let task = Task { try await sut.get(from: anyURL()) }
        for await _ in loadingStarted { break }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    // MARK: - Helpers

    private func makeSUT(configuration: URLSessionConfiguration = .ephemeral) -> URLSessionHTTPClient {
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        return URLSessionHTTPClient(session: session)
    }

    private func anyURL() -> URL {
        URL(string: "https://any-url.com")!
    }

    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }

    private func anyData() -> Data {
        Data("any data".utf8)
    }

    private final class URLProtocolStub: URLProtocol {
        private enum Stub {
            case load(data: Data?, response: URLResponse?, error: Error?)
            case neverComplete(onStartLoading: @Sendable () -> Void)
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
            state.withLock { $0.stub = .load(data: nil, response: nil, error: error) }
        }

        static func stub(data: Data?, response: URLResponse) {
            state.withLock { $0.stub = .load(data: data, response: response, error: nil) }
        }

        static func stubNeverCompleting(onStartLoading: @escaping @Sendable () -> Void) {
            state.withLock { $0.stub = .neverComplete(onStartLoading: onStartLoading) }
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

            switch stub {
            case let .load(data, response, error):
                if let response {
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }

                if let data {
                    client?.urlProtocol(self, didLoad: data)
                }

                if let error {
                    client?.urlProtocol(self, didFailWithError: error)
                } else {
                    client?.urlProtocolDidFinishLoading(self)
                }

            case let .neverComplete(onStartLoading):
                onStartLoading()

            case nil:
                client?.urlProtocolDidFinishLoading(self)
            }
        }

        override func stopLoading() {}
    }
}
