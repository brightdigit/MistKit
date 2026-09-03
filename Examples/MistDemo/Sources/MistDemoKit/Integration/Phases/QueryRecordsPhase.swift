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

internal import Foundation
internal import MistKit

internal struct QueryRecordsPhase: IntegrationPhase {
  internal typealias Input = CreatedRecordNames
  internal typealias Output = NoState

  internal static let title = "Query records by type"
  internal static let emoji = "🔍"
  internal static let apiName = "queryRecords"

  internal func run(
    input: CreatedRecordNames, context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    do {
      let records = try await context.service.queryAllRecords(
        recordType: MistDemoConfig.recordType,
        database: context.database
      )
      print("✅ Queried \(records.count) record(s) of type '\(MistDemoConfig.recordType)'")
      if context.verbose {
        let ours = records.filter { input.names.contains($0.recordName.rawValue) }
        print("   Found \(ours.count) of our \(input.names.count) test records")
      }
    } catch {
      // `NOT_FOUND` now has its own case, so no enum destructuring with a
      // literal is needed here — which also sidesteps the Swift 6.3 SIL
      // miscompile (MandatoryAllocBoxToStack) noted in SWIFT_COMPILER_BUG.md.
      guard case CloudKitError.notFound = error else {
        throw error
      }
      // Schema propagation in development can lag behind the first write.
      // LookupRecordsPhase already verifies the records exist by name.
      print("⚠️  queryRecords returned NOT_FOUND — schema may not be indexed yet (non-fatal)")
    }

    return NoState()
  }
}
