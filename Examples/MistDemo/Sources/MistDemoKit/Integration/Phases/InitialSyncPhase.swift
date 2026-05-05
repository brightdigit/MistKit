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

struct InitialSyncPhase: IntegrationPhase {
  typealias Input = [String]
  typealias Output = String?

  let title = "Initial sync (fetch all changes)"
  let emoji = "🔄"
  let apiName = "fetchRecordChanges"

  func extractInput(from state: PhaseState) throws -> [String] {
    state.createdRecordNames
  }

  func apply(output: String?, to state: inout PhaseState) {
    state.syncToken = output
  }

  func run(input: [String], context: PhaseContext) async throws -> String? {
    print("\n\(emoji) \(title)")

    do {
      let initialResult = try await context.service.fetchRecordChanges()

      print("✅ Fetched \(initialResult.records.count) records")

      if context.verbose {
        if let token = initialResult.syncToken {
          print("   Sync token: \(token.prefix(30))...")
        }
        print("   More coming: \(initialResult.moreComing)")
      }

      let ourRecords = initialResult.records.filter { input.contains($0.recordName) }
      print("   Found \(ourRecords.count) of our test records")

      if ourRecords.count != input.count && context.verbose {
        print("   ⚠️  Expected \(input.count), found \(ourRecords.count)")
        print("   (Records may not be immediately available)")
      }

      return initialResult.syncToken
    } catch {
      print(
        "⚠️  fetchRecordChanges failed (non-fatal, change tracking requires custom zones): \(error)"
      )
      return nil
    }
  }
}
