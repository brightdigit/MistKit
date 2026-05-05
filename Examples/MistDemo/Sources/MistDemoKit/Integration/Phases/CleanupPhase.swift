//
//  CleanupPhase.swift
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

struct CleanupPhase: IntegrationPhase, CleanupPhaseMarker {
  typealias Input = [String]
  typealias Output = Void

  let title = "Cleanup test records"
  let emoji = "🧹"
  let apiName = "deleteRecord"

  func extractInput(from state: PhaseState) throws -> [String] {
    state.createdRecordNames
  }

  func apply(output: Void, to state: inout PhaseState) {
    state.createdRecordNames = []
  }

  func run(input: [String], context: PhaseContext) async throws {
    print("\n\(emoji) \(title)")

    var deletedCount = 0

    // Use forceDelete so no recordChangeTag is required.
    let deleteOps = input.map { recordName in
      RecordOperation(
        operationType: .forceDelete,
        recordType: IntegrationTestData.recordType,
        recordName: recordName
      )
    }

    do {
      _ = try await context.service.modifyRecords(deleteOps)
      deletedCount = input.count
      if context.verbose {
        for name in input { print("   ✅ Deleted: \(name)") }
      }
    } catch {
      if context.verbose { print("   ⚠️  Batch delete failed: \(error)") }
    }

    print("✅ Deleted \(deletedCount) test records")

    if deletedCount < input.count {
      print("   ⚠️  Failed to delete \(input.count - deletedCount) records")
    }
  }
}
