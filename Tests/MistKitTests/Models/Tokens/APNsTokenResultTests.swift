//
//  APNsTokenResultTests.swift
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
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

@Suite("APNsTokenResult Conversion")
internal struct APNsTokenResultTests {
  /// Runs `body`, expecting it to throw `error`, with the DEBUG assertion
  /// handler suppressed so the throw is observed rather than trapped.
  private func expectThrow<E: Error & Equatable>(
    _ error: E,
    _ body: () throws -> Void
  ) {
    ConversionFailureReporter.$assertionHandler.withValue(
      { _, _, _ in },
      operation: {
        #expect(throws: error) {
          try body()
        }
      }
    )
  }

  @Test("maps TokenResponse fields, renaming webcAuthToken")
  internal func mapsFields() throws {
    let response = Components.Schemas.TokenResponse(
      apnsToken: "apns-abc",
      webcAuthToken: "web-xyz"
    )
    let result = try APNsTokenResult(from: response)
    #expect(result.apnsToken == "apns-abc")
    #expect(result.webAuthToken == "web-xyz")
  }

  @Test("missing apnsToken is a conversion failure")
  internal func missingAPNsTokenThrows() throws {
    let response = Components.Schemas.TokenResponse(webcAuthToken: "web-xyz")
    expectThrow(ConversionError.tokenMissingField(fieldName: "apnsToken")) {
      _ = try APNsTokenResult(from: response)
    }
  }

  @Test("missing webcAuthToken is a conversion failure")
  internal func missingWebAuthTokenThrows() throws {
    let response = Components.Schemas.TokenResponse(apnsToken: "apns-abc")
    expectThrow(ConversionError.tokenMissingField(fieldName: "webcAuthToken")) {
      _ = try APNsTokenResult(from: response)
    }
  }

  @Test("APNsEnvironment maps to the createToken payload")
  internal func environmentMapping() {
    #expect(
      Operations.createToken.Input.Body.jsonPayload.apnsEnvironmentPayload(from: .development)
        == .development
    )
    #expect(
      Operations.createToken.Input.Body.jsonPayload.apnsEnvironmentPayload(from: .production)
        == .production
    )
  }
}
