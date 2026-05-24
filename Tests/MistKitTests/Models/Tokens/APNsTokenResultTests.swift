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

  @Test("maps TokenResponse fields including environment and webcourierURL")
  internal func mapsFields() throws {
    let response = Components.Schemas.TokenResponse(
      apnsEnvironment: .development,
      apnsToken: "apns-abc",
      webcourierURL: "https://webcourier.icloud.com/abc"
    )
    let result = try APNsTokenResult(from: response)
    #expect(result.environment == .development)
    #expect(result.apnsToken == "apns-abc")
    #expect(result.webcourierURL == URL(string: "https://webcourier.icloud.com/abc"))
  }

  @Test("production environment round-trips")
  internal func productionEnvironment() throws {
    let response = Components.Schemas.TokenResponse(
      apnsEnvironment: .production,
      apnsToken: "apns-prod",
      webcourierURL: "https://webcourier.icloud.com/prod"
    )
    let result = try APNsTokenResult(from: response)
    #expect(result.environment == .production)
  }

  @Test("malformed webcourierURL is a conversion failure")
  internal func malformedURLThrows() throws {
    let response = Components.Schemas.TokenResponse(
      apnsEnvironment: .development,
      apnsToken: "apns-abc",
      webcourierURL: ""
    )
    expectThrow(ConversionError.tokenMissingField(fieldName: "webcourierURL")) {
      _ = try APNsTokenResult(from: response)
    }
  }

  @Test("APNsEnvironment maps to both request payloads and back from response")
  internal func environmentMapping() {
    #expect(
      Operations.createToken.Input.Body.jsonPayload.apnsEnvironmentPayload(from: .development)
        == .development
    )
    #expect(
      Operations.createToken.Input.Body.jsonPayload.apnsEnvironmentPayload(from: .production)
        == .production
    )
    #expect(
      Operations.registerToken.Input.Body.jsonPayload.apnsEnvironmentPayload(from: .development)
        == .development
    )
    #expect(
      Operations.registerToken.Input.Body.jsonPayload.apnsEnvironmentPayload(from: .production)
        == .production
    )
    #expect(APNsEnvironment(from: .development) == .development)
    #expect(APNsEnvironment(from: .production) == .production)
  }
}
