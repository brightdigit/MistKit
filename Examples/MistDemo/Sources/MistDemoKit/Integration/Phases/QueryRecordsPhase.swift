//
//  QueryRecordsPhase.swift
//  MistDemo
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
import MistKit

struct QueryRecordsPhase: IntegrationPhase {
  typealias Input = CreatedRecordNames
  typealias Output = NoState

  static let title = "Query records by type"
  static let emoji = "🔍"
  static let apiName = "queryRecords"

  func run(input: CreatedRecordNames, context: PhaseContext) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    do {
      let records = try await context.service.queryRecords(
        recordType: IntegrationTestData.recordType
      )
      print("✅ Queried \(records.count) record(s) of type '\(IntegrationTestData.recordType)'")
      if context.verbose {
        let ours = records.filter { input.names.contains($0.recordName) }
        print("   Found \(ours.count) of our \(input.names.count) test records")
      }
    } catch CloudKitError.httpErrorWithDetails(statusCode: 404, serverErrorCode: _, reason: _)
      where true
    {
      // Schema propagation in development can lag behind the first write.
      // LookupRecordsPhase already verifies the records exist by name.
      print("⚠️  queryRecords returned NOT_FOUND — schema may not be indexed yet (non-fatal)")
    }

    return NoState()
  }
}
