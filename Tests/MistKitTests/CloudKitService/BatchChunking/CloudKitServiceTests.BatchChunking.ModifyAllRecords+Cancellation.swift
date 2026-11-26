//
//  CloudKitServiceTests.BatchChunking.ModifyAllRecords+Cancellation.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Foundation
internal import HTTPTypes
internal import OpenAPIRuntime
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.BatchChunking.ModifyAllRecords {
  /// A transport that answers like `MockTransport`, then cancels the task
  /// that sent the request.
  private struct CancellingTransport: ClientTransport, Sendable {
    let inner: MockTransport

    func send(
      _ request: HTTPRequest,
      body: HTTPBody?,
      baseURL: URL,
      operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
      let response = try await inner.send(
        request,
        body: body,
        baseURL: baseURL,
        operationID: operationID
      )
      withUnsafeCurrentTask { $0?.cancel() }
      return response
    }
  }

  @Test("a cancelled task sends nothing and throws the same shape")
  internal func cancelledBeforeFirstRequest() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let provider = await Self.provider([])
    let service = try CloudKitServiceTests.BatchChunking.makeUserService(provider: provider)
    let names = Self.names("n", 3)

    let failure = try await Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return try await Self.incomplete(Self.operations(names), service: service)
    }.value

    #expect(failure.completed.isEmpty)
    #expect(Self.recordNames(failure.unsent) == names)
    guard case .underlyingError(let error) = failure.underlying else {
      Issue.record("expected .underlyingError, got \(failure.underlying)")
      return
    }
    #expect(error is CancellationError)
    #expect(await provider.callCount(for: Self.operationID) == 0)
  }

  @Test("cancellation during a request stops before the next one")
  internal func cancelledBetweenRequests() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let provider = await Self.provider([
      try Self.modified(["n0", "n1"]),
      try Self.modified(["n2"]),
    ])
    let service = try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(
        apiAuth: APICredentials(
          apiToken: TestConstants.apiToken,
          webAuthToken: TestConstants.webAuthToken
        )
      ),
      transport: CancellingTransport(inner: MockTransport(responseProvider: provider))
    )

    // A separate task, so the transport cancels it and not the test.
    let failure = try await Task {
      try await Self.incomplete(Self.operations(Self.names("n", 3)), service: service)
    }.value

    #expect(Self.recordNames(failure.completed) == ["n0", "n1"])
    #expect(Self.recordNames(failure.unsent) == ["n2"])
    guard case .underlyingError(let error) = failure.underlying else {
      Issue.record("expected .underlyingError, got \(failure.underlying)")
      return
    }
    #expect(error is CancellationError)
    #expect(await provider.callCount(for: Self.operationID) == 1)
  }
}
