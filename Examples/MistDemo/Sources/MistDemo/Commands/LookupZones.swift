//
//  LookupZones.swift
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

/// Look up specific CloudKit zones by name
struct LookupZones: AsyncParsableCommand, CloudKitCommand {
    static let configuration = CommandConfiguration(
        commandName: "lookup-zones",
        abstract: "Look up specific CloudKit zones by name"
    )

    @Option(name: .shortAndLong, help: "CloudKit container identifier")
    var containerIdentifier: String = "iCloud.com.brightdigit.MistDemo"

    @Option(name: .shortAndLong, help: "CloudKit API token")
    var apiToken: String = ""

    @Option(name: .long, help: "Environment (development or production)")
    var environment: String = "development"

    @Argument(help: "Zone names to lookup (comma-separated)")
    var zoneNames: String = "_defaultZone"

    func run() async throws {
        print("\n" + String(repeating: "=", count: 60))
        print("🔍 Lookup CloudKit Zones")
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

        let zoneNamesList = zoneNames.split(separator: ",").map(String.init)
        let zoneIDs = zoneNamesList.map { ZoneID(zoneName: $0, ownerName: nil) }

        print("\n📋 Looking up \(zoneIDs.count) zone(s):")
        for zoneName in zoneNamesList {
            print("   - \(zoneName)")
        }

        do {
            let zones = try await service.lookupZones(zoneIDs: zoneIDs)
            print("\n✅ Found \(zones.count) zone(s):")
            for zone in zones {
                print("   - \(zone.zoneName)")
                if let owner = zone.ownerRecordName {
                    print("     Owner: \(owner)")
                }
                if !zone.capabilities.isEmpty {
                    print("     Capabilities: \(zone.capabilities.joined(separator: ", "))")
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
        print("✅ Lookup completed!")
        print(String(repeating: "=", count: 60))
    }
}
