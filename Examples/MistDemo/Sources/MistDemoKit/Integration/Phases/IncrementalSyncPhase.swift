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

struct IncrementalSyncPhase: IntegrationPhase {
  struct Input {
    let syncToken: String?
    let recordNames: [String]
  }
  typealias Output = Void

  let title = "Incremental sync (fetch only changes)"
  let emoji = "🔄"
  let apiName = "fetchRecordChanges"

  func extractInput(from state: PhaseState) throws -> Input {
    Input(syncToken: state.syncToken, recordNames: state.createdRecordNames)
  }

  func run(input: Input, context: PhaseContext) async throws {
    print("\n\(emoji) \(title)")

    guard let token = input.syncToken else {
      print(
        "⚠️  No sync token available — skipping incremental sync (change tracking requires custom zones)"
      )
      return
    }

    if context.verbose {
      print("   Using sync token: \(token.prefix(30))...")
    }

    do {
      let incrementalResult = try await context.service.fetchRecordChanges(syncToken: token)

      print("✅ Fetched \(incrementalResult.records.count) changed records")

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
  }
}
