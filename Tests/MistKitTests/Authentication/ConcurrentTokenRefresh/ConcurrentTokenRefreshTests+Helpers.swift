internal import Foundation
internal import HTTPTypes
internal import OpenAPIRuntime
internal import Testing

@testable import MistKit

extension ConcurrentTokenRefreshTests {
  /// Creates a standard test request used across the concurrent suites.
  internal static func makeRequest() -> HTTPRequest {
    HTTPRequest(
      method: .get,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/database/1/iCloud.com.example.app/private/records/query"
    )
  }

  /// Returns a next-handler closure that always succeeds with `200 OK`.
  internal static func successNextHandler()
    -> @Sendable (HTTPRequest, HTTPBody?, URL) async throws
    -> (HTTPResponse, HTTPBody?)
  {
    { _, _, _ in (HTTPResponse(status: .ok), nil) }
  }

  /// Fans out `count` concurrent middleware calls and gathers their results.
  internal static func runConcurrent(
    middleware: AuthenticationMiddleware,
    request: HTTPRequest,
    baseURL: URL,
    next:
      @escaping @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (
        HTTPResponse, HTTPBody?
      ),
    count: Int
  ) async -> [Bool] {
    let tasks = (1...count).map { _ in
      Task {
        await middleware.interceptWithMiddleware(
          request: request,
          baseURL: baseURL,
          operationID: TestConstants.operationID,
          next: next
        )
      }
    }

    return await withTaskGroup(of: Bool.self) { group in
      for task in tasks {
        group.addTask { await task.value }
      }

      var results: [Bool] = []
      for await result in group {
        results.append(result)
      }
      return results
    }
  }
}
