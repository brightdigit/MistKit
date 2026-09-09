//
//  CloudKitServiceTests.FetchZoneChanges+DeprecatedAPI.swift
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

/// Non-deprecated protocol surface so FetchZoneChanges tests can call the
/// Apple-deprecated `zones/changes` wrappers without emitting
/// `DeprecatedDeclaration` warnings (Swift Testing forbids `@available` on
/// `@Suite`/`@Test`, so call-site silencing isn't available there).
internal protocol FetchZoneChangesAPI: Sendable {
  func fetchZoneChanges(
    syncToken: String?,
    database: Database
  ) async throws(CloudKitError) -> ZoneChangesResult

  func fetchAllZoneChanges(
    syncToken: String?,
    maxPages: Int,
    database: Database
  ) async throws(CloudKitError) -> (zones: [ZoneInfo], syncToken: String?)
}

extension CloudKitService: FetchZoneChangesAPI {}

extension CloudKitServiceTests.FetchZoneChanges {
  /// Invokes ``CloudKitService/fetchZoneChanges(syncToken:database:)`` via
  /// ``FetchZoneChangesAPI`` so the deprecated concrete symbol isn't named at
  /// the test call site.
  internal static func fetchZoneChanges(
    _ service: CloudKitService,
    syncToken: String? = nil,
    database: Database = .private
  ) async throws(CloudKitError) -> ZoneChangesResult {
    try await (service as any FetchZoneChangesAPI).fetchZoneChanges(
      syncToken: syncToken,
      database: database
    )
  }

  /// Invokes ``CloudKitService/fetchAllZoneChanges(syncToken:maxPages:database:)``
  /// via ``FetchZoneChangesAPI`` so the deprecated concrete symbol isn't named
  /// at the test call site.
  internal static func fetchAllZoneChanges(
    _ service: CloudKitService,
    syncToken: String? = nil,
    maxPages: Int = 1_000,
    database: Database = .private
  ) async throws(CloudKitError) -> (zones: [ZoneInfo], syncToken: String?) {
    try await (service as any FetchZoneChangesAPI).fetchAllZoneChanges(
      syncToken: syncToken,
      maxPages: maxPages,
      database: database
    )
  }
}
