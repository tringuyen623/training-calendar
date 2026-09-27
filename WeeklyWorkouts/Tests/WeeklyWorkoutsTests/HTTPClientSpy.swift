import Foundation
import WeeklyWorkouts

final class HTTPClientSpy: HTTPClient {
    private(set) var requestedURLs: [URL] = []
    private var result: Result<(Data, HTTPURLResponse), Error> = .failure(NSError(domain: "not stubbed", code: 0))

    func stub(error: Error) {
        result = .failure(error)
    }

    func stub(statusCode: Int, data: Data) {
        result = .success((data, HTTPURLResponse(statusCode: statusCode)))
    }

    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        requestedURLs.append(url)
        return try result.get()
    }
}

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: URL(string: "https://any-url.com")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
