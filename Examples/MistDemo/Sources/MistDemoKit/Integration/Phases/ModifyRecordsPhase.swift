//
//  ModifyRecordsPhase.swift
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

internal struct ModifyRecordsPhase: IntegrationPhase {
  internal typealias Input = CreatedRecordNames
  internal typealias Output = NoState

  internal static let title = "Modify some records"
  internal static let emoji = "\u{270F}\u{FE0F} "
  internal static let apiName = "updateRecord"

  internal func run(
    input: CreatedRecordNames, context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    let recordsToUpdate = Array(input.names.prefix(min(3, input.names.count)))

    let operations = recordsToUpdate.enumerated().map { offset, recordName in
      RecordOperation(
        operationType: .forceReplace,
        recordType: IntegrationTestData.recordType,
        recordName: recordName,
        fields: [
          "title": .string("Updated Record \(offset + 1)")
        ]
      )
    }

    _ = try await context.service.modifyRecords(
      operations,
      database: context.database
    )

    if context.verbose {
      for recordName in recordsToUpdate {
        print("   ✅ Updated: \(recordName)")
      }
    }

    print("✅ Updated \(recordsToUpdate.count) records")

    return NoState()
  }
}
