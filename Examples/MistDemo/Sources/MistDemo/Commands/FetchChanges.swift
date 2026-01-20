//
//  FetchChanges.swift
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

import ArgumentParser
import Foundation
import MistKit

/// Fetch record changes with incremental sync
struct FetchChanges: AsyncParsableCommand, CloudKitCommand {
    static let configuration = CommandConfiguration(
        commandName: "fetch-changes",
        abstract: "Fetch record changes with incremental sync"
    )

    @Option(name: .shortAndLong, help: "CloudKit container identifier")
    var containerIdentifier: String = "iCloud.com.brightdigit.MistDemo"

    @Option(name: .shortAndLong, help: "CloudKit API token")
    var apiToken: String = ""

    @Option(name: .long, help: "Environment (development or production)")
    var environment: String = "development"

    @Option(name: .long, help: "Sync token from previous fetch")
    var syncToken: String?

    @Option(name: .long, help: "Zone name (default: _defaultZone)")
    var zone: String = "_defaultZone"

    @Flag(name: .long, help: "Fetch all changes automatically with pagination")
    var fetchAll: Bool = false

    @Option(name: .long, help: "Maximum results per page (1-200)")
    var limit: Int?

    func run() async throws {
        print("\n" + String(repeating: "=", count: 60))
        print("🔄 Fetch Record Changes")
        print(String(repeating: "=", count: 60))

        let resolvedToken = resolvedApiToken()

        guard !resolvedToken.isEmpty else {
            print("\n❌ Error: CloudKit API token is required")
            print("   Provide it via --api-token or set CLOUDKIT_API_TOKEN environment variable")
            print("   Get your API token from: https://icloud.developer.apple.com/dashboard/")
            return
        }

        let tokenManager = APITokenManager(apiToken: resolvedToken)
        let service = try CloudKitService(
            containerIdentifier: containerIdentifier,
            tokenManager: tokenManager,
            environment: cloudKitEnvironment(),
            database: .public
        )

        do {
            if fetchAll {
                print("\n📦 Fetching all changes (automatic pagination)...")
                if let token = syncToken {
                    print("   Using sync token: \(token.prefix(20))...")
                } else {
                    print("   Performing initial fetch (no sync token)")
                }

                let (records, newToken) = try await service.fetchAllRecordChanges(
                    syncToken: syncToken
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
                if let token = syncToken {
                    print("   Using sync token: \(token.prefix(20))...")
                } else {
                    print("   Performing initial fetch (no sync token)")
                }

                let result = try await service.fetchRecordChanges(
                    syncToken: syncToken,
                    resultsLimit: limit ?? 10
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
        } catch let error as CloudKitError {
            print("\n❌ CloudKit Error: \(error)")
            throw error
        } catch {
            print("\n❌ Error: \(error)")
            throw error
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
