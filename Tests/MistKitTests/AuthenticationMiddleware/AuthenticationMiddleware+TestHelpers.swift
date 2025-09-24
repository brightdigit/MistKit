import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

extension AuthenticationMiddleware {
  /// Test helper to intercept request and return a boolean result
  func interceptWithMiddleware(
    request: HTTPRequest,
    baseURL: URL,
    operationID: String,
    next: @escaping (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async -> Bool {
    do {
      _ = try await intercept(
        request,
        body: nil as HTTPBody?,
        baseURL: baseURL,
        operationID: operationID,
        next: next
      )
      return true
    } catch {
      return false
    }
  }
}
