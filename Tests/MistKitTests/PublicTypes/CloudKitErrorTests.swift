//
//  CloudKitErrorTests.swift
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

import Foundation
import Testing

@testable import MistKit

@Suite("CloudKitError")
internal struct CloudKitErrorTests {
  @Test(".missingCredentials with .notConfigured describes as not configured")
  internal func missingCredentialsNotConfiguredDescribesAsNotConfigured() throws {
    let error = CloudKitError.missingCredentials(
      database: .public(.prefers(.webAuth)),
      availability: .notConfigured,
      reason: "no API token provided"
    )

    let description = try #require(error.errorDescription)
    #expect(description.contains("public"))
    #expect(description.contains("not configured"))
    #expect(!description.contains("required by preference"))
    #expect(description.contains("no API token provided"))
  }

  @Test(".missingCredentials with .preferenceRequired describes as preference required")
  internal func missingCredentialsPreferenceRequiredDescribesAsPreferenceRequired() throws {
    let error = CloudKitError.missingCredentials(
      database: .public(.requires(.webAuth)),
      availability: .preferenceRequired,
      reason: "web-auth preference required"
    )

    let description = try #require(error.errorDescription)
    #expect(description.contains("public"))
    #expect(description.contains("required by preference but not configured"))
    #expect(description.contains("web-auth preference required"))
  }
}
