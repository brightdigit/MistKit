//
//  DemoInFilterCommand.swift
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

/// Demonstrates the IN/NOT_IN QueryFilter fix (issue #192) end-to-end.
///
/// The command:
///   1. Creates three Note records with index values 10, 20, 30
///   2. Queries them back using QueryFilter.in("index", [10, 30])
///      — expects exactly 2 results, confirming type-preserving serialization works
///   3. Cleans up all three created records
public struct DemoInFilterCommand: MistDemoCommand {
  /// The configuration type.
  public typealias Config = MistDemoConfig
  /// The command name.
  public static let commandName = "demo-in-filter"
  /// The command abstract.
  public static let abstract =
    "Demonstrates IN/NOT_IN QueryFilter against CloudKit"
  /// The command help text.
  public static let helpText = """
    DEMO-IN-FILTER - IN/NOT_IN QueryFilter fix (issue #192)

    USAGE:
      mistdemo demo-in-filter [options]

    DESCRIPTION:
      Creates three Note records with index 10, 20, 30,
      queries with IN filter for [10, 30], expects 2 results.
    """

  private let config: MistDemoConfig

  /// Creates a new instance.
  public init(config: MistDemoConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      print("demo-in-filter requires macOS 11+ / iOS 14+")
      return
    }

    let client = try MistKitClientFactory.create(for: config)
    let tag = Int(Date().timeIntervalSince1970)
    let recordType = "Note"

    let createdNames = try await createDemoRecords(
      client: client, recordType: recordType, tag: tag
    )

    try await verifyAndQueryRecords(
      client: client,
      recordType: recordType,
      createdNames: createdNames
    )

    try await cleanupDemoRecords(
      client: client,
      recordType: recordType,
      createdNames: createdNames
    )
  }

  private func createDemoRecords(
    client: CloudKitService,
    recordType: String,
    tag: Int
  ) async throws -> [String] {
    print("Creating 3 Note records with index 10, 20, 30...")
    let indexValues: [Int] = [10, 20, 30]
    var createdNames: [String] = []
    for idx in indexValues {
      let record = try await client.createRecord(
        recordType: recordType,
        fields: [
          "title": .string("demo-in-filter-\(tag)-idx\(idx)"),
          "index": .int64(idx),
        ],
        database: config.database
      )
      createdNames.append(record.recordName)
      print("  Created \(record.recordName) (index=\(idx))")
    }
    return createdNames
  }

  private func verifyAndQueryRecords(
    client: CloudKitService,
    recordType: String,
    createdNames: [String]
  ) async throws {
    print("\nVerifying records are queryable...")
    let allRecords = try await client.queryRecords(
      Query(recordType: recordType),
      limit: 200,
      database: config.database
    ).records
    let visible = allRecords.filter {
      createdNames.contains($0.recordName)
    }
    print("  Visible: \(visible.count)")
    if visible.count < 3 {
      try await Task.sleep(nanoseconds: 2_000_000_000)
    }

    print("\nQuerying with IN filter for [10, 30]...")
    let results = try await client.queryRecords(
      Query(
        recordType: recordType,
        filters: [.in("index", [.int64(10), .int64(30)])]
      ),
      limit: 200,
      database: config.database
    ).records

    let matching = results.filter {
      createdNames.contains($0.recordName)
    }
    print("Matching demo records: \(matching.count) (expected 2)")

    if matching.count == 2 {
      print("\n  IN filter works correctly")
    } else {
      print("\n  Unexpected result count")
    }
  }

  private func cleanupDemoRecords(
    client: CloudKitService,
    recordType: String,
    createdNames: [String]
  ) async throws {
    print("\nDeleting demo records...")
    for name in createdNames {
      let operation = RecordOperation(
        operationType: .forceDelete,
        recordType: recordType,
        recordName: name
      )
      _ = try await client.modifyRecords(
        [operation],
        database: config.database
      )
      print("  Deleted \(name)")
    }
    print("Done.")
  }
}
