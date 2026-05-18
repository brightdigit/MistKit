//
//  CloudKitServiceTests.FetchChanges+Concurrent.swift
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

extension CloudKitServiceTests.FetchChanges {
  @Suite("Concurrent")
  internal struct Concurrent {
    @Test("fetchAllRecordChanges() is safe under concurrent calls from N tasks")
    internal func fetchAllRecordChangesConcurrent() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.FetchChanges.makeSuccessfulService(
        recordCount: 3,
        moreComing: false,
        syncToken: "concurrent-token"
      )
      let taskCount = 8

      let results = await withTaskGroup(
        of: (records: [RecordInfo], syncToken: String?)?.self
      ) { group in
        for _ in 0..<taskCount {
          group.addTask {
            try? await service.fetchAllRecordChanges(database: .public(.prefers(.serverToServer)))
          }
        }
        var collected: [(records: [RecordInfo], syncToken: String?)] = []
        for await result in group {
          if let result {
            collected.append(result)
          }
        }
        return collected
      }

      #expect(
        results.count == taskCount,
        "All \(taskCount) concurrent calls should succeed"
      )
      for result in results {
        #expect(result.records.count == 3)
        #expect(result.syncToken == "concurrent-token")
      }
    }
  }
}
