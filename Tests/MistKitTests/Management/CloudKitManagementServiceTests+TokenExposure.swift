//
//  CloudKitManagementServiceTests+TokenExposure.swift
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
internal import Testing

@testable import MistKit

extension CloudKitManagementServiceTests {
  /// The management token must not surface in any text a caller might log:
  /// the service's own description, or any error it throws.
  @Suite("Token exposure")
  internal struct TokenExposure {
    private static func reveals(_ value: Any) -> Bool {
      var dumped = ""
      dump(value, to: &dumped)
      return [String(describing: value), String(reflecting: value), dumped]
        .contains { $0.contains(CloudKitManagementServiceTests.token) }
    }

    @Test("The service never prints the token")
    internal func service() {
      let (service, _) = makeService(response: ProvisionalManagementFixtures.textResponse(""))
      #expect(!Self.reveals(service))
    }

    @Test(
      "Thrown errors never print the token",
      arguments: [
        ProvisionalManagementFixtures.jsonResponse(
          ProvisionalManagementFixtures.requestErrorJSON,
          statusCode: 401
        ),
        ProvisionalManagementFixtures.jsonResponse(#"{"code": 500}"#, statusCode: 500),
        ProvisionalManagementFixtures.textResponse("Bad Gateway", statusCode: 502),
        ResponseConfig(statusCode: 200, body: Data([0xFF])),
        ResponseConfig.timeout(),
      ]
    )
    internal func errors(response: ResponseConfig) async throws {
      let (service, _) = makeService(response: response)
      let error = try #require(await exportTextError(service))
      #expect(!Self.reveals(error))
      #expect(!error.localizedDescription.contains(CloudKitManagementServiceTests.token))
    }
  }
}
