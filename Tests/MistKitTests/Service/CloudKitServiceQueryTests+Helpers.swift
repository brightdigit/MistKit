//
//  CloudKitServiceQueryTests+Helpers.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

extension CloudKitServiceQueryTests {
  /// Create service for validation error testing
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal static func makeValidationErrorService(
    _ errorType: ValidationErrorType
  ) throws -> CloudKitService {
    let transport = MockTransport(
      responseProvider: .validationError(errorType)
    )
    return try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token",
      transport: transport
    )
  }

  /// Create service for successful operations
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal static func makeSuccessfulService(
    records: [String: Any] = [:]
  ) throws -> CloudKitService {
    let transport = MockTransport(
      responseProvider: .successfulQuery(records: records)
    )
    return try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token",
      transport: transport
    )
  }

  /// Create service for auth errors
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal static func makeAuthErrorService() throws -> CloudKitService {
    let transport = MockTransport(
      responseProvider: .authenticationError()
    )
    return try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token",
      transport: transport
    )
  }
}
