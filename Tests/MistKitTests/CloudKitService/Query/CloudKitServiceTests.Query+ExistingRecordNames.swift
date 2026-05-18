//
//  CloudKitServiceTests.Query+ExistingRecordNames.swift
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

extension CloudKitServiceTests.Query {
  @Suite("fetchExistingRecordNames", .enabled(if: Platform.isCryptoAvailable))
  internal struct ExistingRecordNames {
    @Test("fetchExistingRecordNames returns the set of existing record names")
    internal func fetchExistingRecordNamesReturnsExistingNames() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.QueryPagination.makeSuccessfulService(
        recordCount: 3,
        continuationMarker: nil
      )

      let existing = try await service.fetchExistingRecordNames(
        recordType: "TestRecord",
        database: .public(.prefers(.serverToServer))
      )

      #expect(existing == Set(["record-0", "record-1", "record-2"]))
    }

    @Test("deprecated RecordManaging.queryRecords(recordType:) returns parsed records")
    @available(
      *, deprecated,
      message: "Exercises the deprecated single-page RecordManaging wrapper."
    )
    internal func deprecatedQueryRecordsReturnsRecords() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.QueryPagination.makeSuccessfulService(
        recordCount: 2,
        continuationMarker: nil
      )

      let records = try await service.queryRecords(recordType: "TestRecord")

      #expect(records.count == 2)
      #expect(records.map(\.recordName) == ["record-0", "record-1"])
    }
  }
}
