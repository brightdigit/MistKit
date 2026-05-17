//
//  CloudKitServiceTests.FetchChanges.SuccessCases+Pagination.swift
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

extension CloudKitServiceTests.FetchChanges.SuccessCases {
  @Test("fetchAllRecordChanges() handles moreComing=true with empty first page")
  internal func fetchAllRecordChangesEmptyFirstPage() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try await CloudKitServiceTests.FetchChanges.makePaginatedService(pages: [
      (recordCount: 0, syncToken: "token-1"),
      (recordCount: 3, syncToken: "token-2"),
    ])

    let (records, token) = try await service.fetchAllRecordChanges(
      database: .public(.prefers(.serverToServer))
    )

    #expect(records.count == 3)
    #expect(token == "token-2")
  }

  @Test("fetchAllRecordChanges() accumulates records across three pages")
  internal func fetchAllRecordChangesThreePage() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try await CloudKitServiceTests.FetchChanges.makePaginatedService(pages: [
      (recordCount: 2, syncToken: "token-1"),
      (recordCount: 3, syncToken: "token-2"),
      (recordCount: 2, syncToken: "token-3"),
    ])

    let (records, token) = try await service.fetchAllRecordChanges(
      database: .public(.prefers(.serverToServer))
    )

    #expect(records.count == 7)
    #expect(token == "token-3")
  }
}
