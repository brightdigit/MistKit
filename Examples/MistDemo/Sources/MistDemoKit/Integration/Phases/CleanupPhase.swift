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

internal import Foundation
internal import MistKit

internal struct CleanupPhase: IntegrationPhase, CleanupPhaseMarker {
  internal typealias Input = CreatedRecordNames
  /// Returns an empty `CreatedRecordNames` so the runner clears
  /// `state.createdRecordNames` after a successful cleanup, preventing
  /// `PhasedIntegrationTest.run`'s on-failure cleanup from re-running.
  internal typealias Output = CreatedRecordNames

  internal static let title = "Cleanup test records"
  internal static let emoji = "🧹"
  internal static let apiName = "deleteRecord"

  internal func run(
    input: CreatedRecordNames,
    context: PhaseContext
  ) async throws -> CreatedRecordNames {
    print("\n\(Self.emoji) \(Self.title)")

    var deletedCount = 0

    // Use forceDelete so no recordChangeTag is required.
    let deleteOps = input.names.map { recordName in
      RecordOperation(
        operationType: .forceDelete,
        recordType: IntegrationTestData.recordType,
        recordName: recordName
      )
    }

    do {
      _ = try await context.service.modifyRecords(
        deleteOps,
        database: context.database
      )
      deletedCount = input.names.count
      if context.verbose {
        for name in input.names { print("   ✅ Deleted: \(name)") }
      }
    } catch {
      if context.verbose { print("   ⚠️  Batch delete failed: \(error)") }
    }

    print("✅ Deleted \(deletedCount) test records")

    if deletedCount < input.names.count {
      print("   ⚠️  Failed to delete \(input.names.count - deletedCount) records")
    }

    return CreatedRecordNames([])
  }
}
