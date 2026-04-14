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

import Foundation
import MistKit

/// Demonstrates the IN/NOT_IN QueryFilter fix (issue #192) end-to-end.
///
/// The command:
///   1. Creates three Note records with index values 10, 20, 30
///   2. Queries them back using QueryFilter.in("index", [10, 30])
///      — expects exactly 2 results, confirming type-preserving serialization works
///   3. Cleans up all three created records
public struct DemoInFilterCommand: MistDemoCommand {
    public typealias Config = MistDemoConfig
    public static let commandName = "demo-in-filter"
    public static let abstract = "Demonstrates IN/NOT_IN QueryFilter (issue #192) against CloudKit"
    public static let helpText = """
        DEMO-IN-FILTER - Demonstrate IN/NOT_IN QueryFilter fix (issue #192)

        USAGE:
            mistdemo demo-in-filter [options]

        REQUIRED:
            --api-token <token>        CloudKit API token
            --web-auth-token <token>   Web authentication token

        DESCRIPTION:
            Creates three Note records with index values 10, 20, and 30,
            then queries them back using an IN filter for [10, 30].
            Expects 2 results, confirming that type information is preserved
            in the serialized filter payload (the fix for issue #192).
            Created records are deleted after the demo completes.
        """

    private let config: MistDemoConfig

    public init(config: MistDemoConfig) {
        self.config = config
    }

    public func execute() async throws {
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
            print("demo-in-filter requires macOS 11+ / iOS 14+")
            return
        }

        let client = try MistKitClientFactory.createForPublicDatabase(from: config)
        let tag = Int(Date().timeIntervalSince1970)
        let recordType = "Note"

        // Step 1 — create three records with index values 10, 20, 30
        print("Creating 3 Note records with index values 10, 20, 30…")
        let indexValues: [Int] = [10, 20, 30]
        var createdNames: [String] = []
        for idx in indexValues {
            let record = try await client.createRecord(
                recordType: recordType,
                fields: [
                    "title": .string("demo-in-filter-\(tag)-idx\(idx)"),
                    "index": .int64(idx)
                ]
            )
            createdNames.append(record.recordName)
            print("  Created \(record.recordName)  (index=\(idx))")
        }

        // Step 2 — query back records where index IN [10, 30]
        print("\nQuerying with IN filter for index values [10, 30]…")
        let results = try await client.queryRecords(
            recordType: recordType,
            filters: [.in("index", [.int64(10), .int64(30)])],
            limit: 200
        )

        let matching = results.filter { createdNames.contains($0.recordName) }
        print("Total results returned: \(results.count)")
        print("Matching demo records:  \(matching.count) (expected 2)")
        for record in matching {
            let idx = record.fields["index"].flatMap { if case .int64(let v) = $0 { return v } else { return nil } }
            print("  \(record.recordName)  index=\(idx.map(String.init) ?? "?")")
        }

        if matching.count == 2 {
            print("\n✓ IN filter works correctly — issue #192 fix confirmed")
        } else {
            print("\n✗ Unexpected result count — check CloudKit for details")
        }

        // Step 3 — clean up
        print("\nDeleting demo records…")
        for name in createdNames {
            try await client.deleteRecord(recordType: recordType, recordName: name)
            print("  Deleted \(name)")
        }
        print("Done.")
    }
}
