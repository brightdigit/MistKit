//
//  CloudKitServiceTests.LookupUsersByRecordName+DeprecatedAPI.swift
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

@testable import MistKit

/// Non-deprecated protocol surface so LookupUsersByRecordName tests can call the
/// Apple-deprecated `users/lookup/id` wrapper without emitting
/// `DeprecatedDeclaration` warnings (same pattern as `FetchZoneChangesAPI`).
internal protocol LookupUsersByRecordNameAPI: Sendable {
  func lookupUsersByRecordName(
    _ recordNames: [String]
  ) async throws(CloudKitError) -> [UserIdentity]
}

extension CloudKitService: LookupUsersByRecordNameAPI {}

extension CloudKitServiceTests.LookupUsersByRecordName {
  /// Invokes ``CloudKitService/lookupUsersByRecordName(_:)`` via ``LookupUsersByRecordNameAPI`` so the
  /// deprecated concrete symbol isn't named at the test call site.
  internal static func lookupUsersByRecordName(
    _ service: CloudKitService,
    _ recordNames: [String]
  ) async throws(CloudKitError) -> [UserIdentity] {
    try await (service as any LookupUsersByRecordNameAPI).lookupUsersByRecordName(recordNames)
  }
}
