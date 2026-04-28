//
//  FetchChangesCommand.swift
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

/// Command to fetch record changes with incremental sync
public struct FetchChangesCommand: MistDemoCommand, OutputFormatting {
    public typealias Config = FetchChangesConfig
    public static let commandName = "fetch-changes"
    public static let abstract = "Fetch record changes with incremental sync"
    public static let helpText = """
        FETCH-CHANGES - Fetch record changes with incremental sync

        USAGE:
            mistdemo fetch-changes [options]

        OPTIONS:
            --sync-token <token>       Sync token from previous fetch
            --zone <name>              Zone name (default: "_defaultZone")
            --fetch-all                Fetch all changes with automatic pagination
            --limit <count>            Maximum results per page (1-200)
            --output-format <format>   Output format: json, table, csv, yaml

        EXAMPLES:
            # Fetch initial changes
            mistdemo fetch-changes

            # Fetch with pagination
            mistdemo fetch-changes --fetch-all

            # Incremental sync with token
            mistdemo fetch-changes --sync-token "previous-token"

        NOTES:
            - Save the returned sync token for incremental fetching
            - Use --fetch-all to automatically paginate through all changes
        """

    private let config: FetchChangesConfig

    public init(config: FetchChangesConfig) {
        self.config = config
    }

    public func execute() async throws {
        print("\n" + String(repeating: "=", count: 60))
        print("🔄 Fetch Record Changes")
        print(String(repeating: "=", count: 60))

        let service = try MistKitClientFactory.create(.private, from: config.base)
        let zoneID = ZoneID(zoneName: config.zone, ownerName: nil)

        if config.fetchAll {
            print("\n📦 Fetching all changes (automatic pagination)...")
            if let token = config.syncToken {
                print("   Using sync token: \(token.prefix(20))...")
            } else {
                print("   Performing initial fetch (no sync token)")
            }

            let (records, newToken) = try await service.fetchAllRecordChanges(
                zoneID: zoneID,
                syncToken: config.syncToken
            )
            print("\n✅ Fetched \(records.count) record(s)")
            displayRecords(records, limit: 5)
            if let token = newToken {
                print("\n💾 New sync token: \(token.prefix(20))...")
                print("   Save this token to fetch only new changes next time:")
                print("   mistdemo fetch-changes --sync-token '\(token)'")
            }
        } else {
            print("\n📄 Fetching single page...")
            if let token = config.syncToken {
                print("   Using sync token: \(token.prefix(20))...")
            } else {
                print("   Performing initial fetch (no sync token)")
            }

            let result = try await service.fetchRecordChanges(
                zoneID: zoneID,
                syncToken: config.syncToken,
                resultsLimit: config.limit ?? 10
            )
            print("\n✅ Fetched \(result.records.count) record(s)")
            displayRecords(result.records, limit: 5)

            if result.moreComing {
                print("\n⚠️  More changes available! Use --sync-token with:")
                if let token = result.syncToken {
                    print("   mistdemo fetch-changes --sync-token '\(token)'")
                }
            }

            if let token = result.syncToken {
                print("\n💾 Sync token: \(token.prefix(20))...")
            }
        }

        print("\n" + String(repeating: "=", count: 60))
        print("✅ Fetch completed!")
        print(String(repeating: "=", count: 60))
    }

    private func displayRecords(_ records: [RecordInfo], limit: Int) {
        let displayed = records.prefix(limit)
        for record in displayed {
            print("   📝 \(record.recordType) - \(record.recordName)")
            if !record.fields.isEmpty {
                print("      Fields: \(record.fields.keys.joined(separator: ", "))")
            }
        }
        if records.count > limit {
            print("   ... and \(records.count - limit) more")
        }
    }
}
