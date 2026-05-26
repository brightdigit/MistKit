//
//  CreateRecordsPhase.swift
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

internal struct CreateRecordsPhase: IntegrationPhase {
  internal typealias Input = AssetUploadReceipt
  internal typealias Output = CreatedRecordNames

  internal static let title = "Create records with assets"
  internal static let emoji = "📝"
  internal static let apiName = "createRecord"

  internal func run(
    input: AssetUploadReceipt,
    context: PhaseContext
  ) async throws -> CreatedRecordNames {
    print("\n\(Self.emoji) \(Self.title)")

    if context.verbose {
      print("   Creating \(context.recordCount) records...")
    }

    var createdRecordNames: [String] = []

    for recordIndex in 1...context.recordCount {
      let recordName = "mistkit-test-\(UUID().uuidString.lowercased())"
      let record = try await context.service.createRecord(
        recordType: MistDemoConfig.recordType,
        recordName: recordName,
        fields: [
          "title": .string("Test Record \(recordIndex)"),
          "index": .int64(recordIndex),
          "image": .asset(input.asset),
        ],
        database: context.database
      )
      createdRecordNames.append(record.recordName)
      if context.verbose {
        print("   ✅ Created: \(record.recordName)")
      }
    }

    guard !createdRecordNames.isEmpty else {
      throw IntegrationTestError.noRecordsCreated
    }

    print("✅ Created \(createdRecordNames.count) records")

    return CreatedRecordNames(createdRecordNames)
  }
}
