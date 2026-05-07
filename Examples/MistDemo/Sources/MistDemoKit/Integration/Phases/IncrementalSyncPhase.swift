//
//  IncrementalSyncPhase.swift
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

internal struct IncrementalSyncPhase: IntegrationPhase {
  internal typealias Input = IncrementalSyncInput
  internal typealias Output = NoState

  internal static let title = "Incremental sync (fetch only changes)"
  internal static let emoji = "🔄"
  internal static let apiName = "fetchRecordChanges"

  internal func run(
    input: IncrementalSyncInput,
    context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    guard let token = input.syncToken else {
      print(
        "⚠️  No sync token available — skipping incremental sync (change tracking requires custom zones)"
      )
      return NoState()
    }

    if context.verbose {
      print("   Using sync token: \(token.prefix(30))...")
    }

    do {
      let incrementalResult = try await context.service.fetchRecordChanges(syncToken: token)

      print("✅ Fetched \(incrementalResult.records.count) changed records")

      // New token intentionally not persisted: no later phase chains off it.
      if context.verbose, let newToken = incrementalResult.syncToken {
        print("   New sync token: \(newToken.prefix(30))...")
      }

      let changedRecords = incrementalResult.records.filter {
        input.recordNames.contains($0.recordName)
      }
      print("   Found \(changedRecords.count) of our modified records")

      if context.verbose && !changedRecords.isEmpty {
        print("   Modified records:")
        for record in changedRecords {
          print("      - \(record.recordName)")
        }
      }
    } catch {
      print("⚠️  fetchRecordChanges (incremental) failed (non-fatal): \(error)")
    }

    return NoState()
  }
}
