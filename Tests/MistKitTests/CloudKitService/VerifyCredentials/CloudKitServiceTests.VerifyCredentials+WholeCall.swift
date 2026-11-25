//
//  CloudKitServiceTests.VerifyCredentials+WholeCall.swift
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
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.VerifyCredentials {
  @Test("one rejected credential doesn't hide the others")
  internal func mixedResults() async throws {
    let (service, _) = Self.makeService(
      credentials: try Self.makeCredentials(webAuth: true, serverToServer: true),
      responses: [
        "getCaller": Self.reply(200, Recorded.caller),
        "listZones": .authenticationError(),
      ]
    )
    let result = try await service.verifyCredentials()
    #expect(result.webAuth.isAccepted)
    #expect(result.serverToServer.error != nil)
    #expect(result.configuredKinds == [.webAuth, .serverToServer])
    #expect(!result.allAccepted)
  }

  @Test("a network failure is a rejection, not a throw")
  internal func networkFailure() async throws {
    let (service, _) = Self.makeService(
      credentials: try Self.makeCredentials(webAuth: true),
      responses: ["getCaller": .connectionLost()]
    )
    let result = try await service.verifyCredentials()
    guard case .rejected(.networkError) = result.webAuth else {
      Issue.record("expected rejected(.networkError), got \(result.webAuth)")
      return
    }
  }

  @Test("a service with a fixed token manager has nothing configured")
  internal func fixedTokenManager() async throws {
    let provider = ResponseProvider.default
    let service = CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      tokenManager: APITokenManager(apiToken: TestConstants.apiToken),
      transport: MockTransport(responseProvider: provider)
    )
    let result = try await service.verifyCredentials()
    #expect(result.configuredKinds.isEmpty)
    #expect(!result.allAccepted)
    #expect(await provider.callCount(for: "getCaller") == 0)
  }

  @Test("throws CancellationError when the task is cancelled")
  internal func cancelled() async throws {
    let (service, _) = Self.makeService(
      credentials: try Self.makeCredentials(webAuth: true),
      responses: ["getCaller": Self.reply(200, Recorded.caller)]
    )
    let task = Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return try await service.verifyCredentials()
    }
    await #expect(throws: CancellationError.self) {
      try await task.value
    }
  }
}
