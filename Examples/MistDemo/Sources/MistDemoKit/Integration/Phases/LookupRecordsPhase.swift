//
//  LookupRecordsPhase.swift
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

struct LookupRecordsPhase: IntegrationPhase {
  typealias Input = [String]
  typealias Output = Void

  let title = "Lookup records by name"
  let emoji = "🔍"
  let apiName = "lookupRecords"

  func extractInput(from state: PhaseState) throws -> [String] {
    state.createdRecordNames
  }

  func run(input: [String], context: PhaseContext) async throws {
    let lookupNames = Array(input.prefix(min(3, input.count)))
    print("\n\(emoji) Lookup \(lookupNames.count) record(s) by name")

    let records = try await context.service.lookupRecords(recordNames: lookupNames)

    print("✅ Looked up \(records.count) record(s)")

    if context.verbose {
      for record in records {
        print("   - \(record.recordName)")
      }
    }
  }
}
