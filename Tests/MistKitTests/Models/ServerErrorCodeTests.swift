//
//  ServerErrorCodeTests.swift
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

internal import Testing

@testable import MistKit

/// Verifies the `RecordOperationFailure.ServerErrorCode` ↔ raw CloudKit string
/// mapping is total in both directions and forward-compatible.
@Suite("ServerErrorCode")
internal struct ServerErrorCodeTests {
  @Test(
    "round-trips every known raw CloudKit string",
    arguments: [
      "ACCESS_DENIED", "ATOMIC_ERROR", "AUTHENTICATION_FAILED",
      "AUTHENTICATION_REQUIRED", "BAD_REQUEST", "CONFLICT", "EXISTS",
      "INTERNAL_ERROR", "NOT_FOUND", "QUOTA_EXCEEDED", "THROTTLED",
      "TRY_AGAIN_LATER", "VALIDATING_REFERENCE_ERROR", "ZONE_NOT_FOUND",
    ]
  )
  internal func roundTrips(rawValue: String) {
    let code = RecordOperationFailure.ServerErrorCode(rawValue: rawValue)
    // A known raw must map to a concrete case, not the forward-compat fallback…
    if case .unknown = code {
      Issue.record("\(rawValue) decoded as .unknown; missing from knownCatalog")
    }
    // …and re-encode back to the identical raw string.
    #expect(code.rawValue == rawValue)
  }

  @Test("preserves an unrecognized code via .unknown")
  internal func preservesUnknown() {
    let code = RecordOperationFailure.ServerErrorCode(rawValue: "FUTURE_CODE")
    #expect(code == .unknown("FUTURE_CODE"))
    #expect(code.rawValue == "FUTURE_CODE")
    #expect(code.statusCode == nil)
    #expect(code.summary == nil)
  }

  @Test("exposes catalog status and summary for every known code")
  internal func knownCodesExposeCatalogMetadata() {
    for entry in CloudKitServerErrorCode.knownCatalog {
      #expect(entry.code.statusCode == entry.statusCode)
      #expect(entry.code.summary == entry.summary)
      #expect(entry.code.rawValue == entry.raw)
    }
  }
}
