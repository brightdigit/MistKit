//
//  InitialSyncPhase.swift
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

internal struct InitialSyncPhase: IntegrationPhase {
  internal typealias Input = CreatedRecordNames
  internal typealias Output = SyncTokenSlot

  internal static let title = "Initial sync (fetch all changes)"
  internal static let emoji = "🔄"
  internal static let apiName = "fetchRecordChanges"

  internal func run(
    input: CreatedRecordNames, context: PhaseContext
  ) async throws -> SyncTokenSlot {
    print("\n\(Self.emoji) \(Self.title)")

    do {
      let initialResult = try await context.service.fetchRecordChanges(
        database: context.database
      )

      print("✅ Fetched \(initialResult.records.count) records")

      if context.verbose {
        if let token = initialResult.syncToken {
          print("   Sync token: \(token.prefix(30))...")
        }
        print("   More coming: \(initialResult.moreComing)")
      }

      let ourRecords = initialResult.records.filter { input.names.contains($0.recordName) }
      print("   Found \(ourRecords.count) of our test records")

      if ourRecords.count != input.names.count && context.verbose {
        print("   ⚠️  Expected \(input.names.count), found \(ourRecords.count)")
        print("   (Records may not be immediately available)")
      }

      return SyncTokenSlot(initialResult.syncToken)
    } catch {
      print(
        "⚠️  fetchRecordChanges failed (non-fatal, change tracking requires custom zones): \(error)"
      )
      return SyncTokenSlot(nil)
    }
  }
}
