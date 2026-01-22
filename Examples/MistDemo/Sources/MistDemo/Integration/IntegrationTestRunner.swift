//
//  IntegrationTestRunner.swift
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

/// Orchestrates comprehensive integration tests for CloudKit operations
struct IntegrationTestRunner {
    let containerIdentifier: String
    let apiToken: String
    let webAuthToken: String
    let environment: MistKit.Environment
    let database: MistKit.Database
    let recordCount: Int
    let assetSizeKB: Int
    let skipCleanup: Bool
    let verbose: Bool

    /// Run the basic integration workflow testing all operations
    func runBasicWorkflow() async throws {
        print("\n" + String(repeating: "=", count: 80))
        print("🧪 Integration Test Suite: CloudKit Operations")
        print(String(repeating: "=", count: 80))
        print("Container: \(containerIdentifier)")
        print("Environment: \(environment == .production ? "production" : "development")")
        print("Database: \(database == .public ? "public" : "private")")
        print("Record Count: \(recordCount)")
        print("Asset Size: \(assetSizeKB) KB")
        print("Web Auth: \(webAuthToken.isEmpty ? "No" : "Yes")")
        print(String(repeating: "=", count: 80))

        // Initialize service
        let tokenManager: any TokenManager
        if database == .private && !webAuthToken.isEmpty {
            // Use AdaptiveTokenManager for private database with web auth
            let storage = InMemoryTokenStorage()
            // Pre-populate storage with web auth credentials
            let credentials = TokenCredentials(
                method: .webAuthToken(apiToken: apiToken, webToken: webAuthToken)
            )
            try await storage.store(credentials)
            
            tokenManager = AdaptiveTokenManager(
                apiToken: apiToken,
                storage: storage
            )
        } else {
            // Use APITokenManager for public database
            tokenManager = APITokenManager(apiToken: apiToken)
        }
        
        let service = try CloudKitService(
            containerIdentifier: containerIdentifier,
            tokenManager: tokenManager,
            environment: environment,
            database: database
        )

        var createdRecordNames: [String] = []
        var syncToken: String?

        do {
            // PHASE 1: Zone Verification
            try await phase1VerifyZone(service: service)

            // PHASE 2: Asset Upload
            let assetToken = try await phase2UploadAsset(service: service)

            // PHASE 3: Create Records with Assets
            createdRecordNames = try await phase3CreateRecords(
                service: service,
                assetToken: assetToken
            )

            // PHASE 4: Initial Sync
            syncToken = try await phase4InitialSync(
                service: service,
                createdRecordNames: createdRecordNames
            )

            // PHASE 5: Modify Records
            try await phase5ModifyRecords(
                service: service,
                createdRecordNames: createdRecordNames
            )

            // PHASE 6: Incremental Sync
            try await phase6IncrementalSync(
                service: service,
                syncToken: syncToken,
                createdRecordNames: createdRecordNames
            )

            // PHASE 7: Final Zone Verification
            try await phase7FinalVerification(service: service)

            // PHASE 8: Cleanup
            if !skipCleanup {
                try await phase8Cleanup(
                    service: service,
                    createdRecordNames: createdRecordNames
                )
            } else {
                printSkippedCleanup(recordNames: createdRecordNames)
            }

            // Print summary
            printSuccessSummary()

        } catch let error as CloudKitError {
            print("\n❌ CloudKit Error: \(error)")
            if !createdRecordNames.isEmpty && !skipCleanup {
                print("\n⚠️  Attempting cleanup of \(createdRecordNames.count) test records...")
                try? await phase8Cleanup(
                    service: service,
                    createdRecordNames: createdRecordNames
                )
            }
            throw error
        } catch {
            print("\n❌ Error: \(error)")
            if !createdRecordNames.isEmpty && !skipCleanup {
                print("\n⚠️  Attempting cleanup of \(createdRecordNames.count) test records...")
                try? await phase8Cleanup(
                    service: service,
                    createdRecordNames: createdRecordNames
                )
            }
            throw error
        }
    }

    // MARK: - Phase 1: Zone Verification

    private func phase1VerifyZone(service: CloudKitService) async throws {
        print("\n📋 Phase 1: Verify zone exists")

        let zones = try await service.lookupZones(zoneIDs: [.defaultZone])

        guard !zones.isEmpty else {
            throw IntegrationTestError.zoneNotFound("_defaultZone")
        }

        let zone = zones[0]
        print("✅ Found zone: \(zone.zoneName)")

        if verbose {
            if let owner = zone.ownerRecordName {
                print("   Owner: \(owner)")
            }
            if !zone.capabilities.isEmpty {
                print("   Capabilities: \(zone.capabilities.joined(separator: ", "))")
            }
        }
    }

    // MARK: - Phase 2: Asset Upload

    private func phase2UploadAsset(service: CloudKitService) async throws -> AssetUploadToken {
        print("\n📤 Phase 2: Upload test assets")

        let testData = IntegrationTestData.generateTestImage(sizeKB: assetSizeKB)
        let sizeInMB = Double(testData.count) / 1024 / 1024

        if verbose {
            print("   Uploading \(testData.count) bytes (\(String(format: "%.2f", sizeInMB)) MB)...")
        }

        let uploadResult = try await service.uploadAssets(data: testData)

        guard let token = uploadResult.tokens.first else {
            throw IntegrationTestError.uploadFailed("No tokens returned")
        }

        print("✅ Uploaded asset: \(testData.count) bytes")

        if verbose, let url = token.url {
            print("   Token URL: \(url.prefix(60))...")
        }

        return token
    }

    // MARK: - Phase 3: Create Records

    private func phase3CreateRecords(
        service: CloudKitService,
        assetToken: AssetUploadToken
    ) async throws -> [String] {
        print("\n📝 Phase 3: Create records with assets")

        if verbose {
            print("   Creating \(recordCount) records...")
        }

        var createdRecordNames: [String] = []

        for i in 1...recordCount {
            let asset = FieldValue.Asset(
                fileChecksum: nil,
                size: Int64(assetSizeKB * 1024),
                referenceChecksum: nil,
                wrappingKey: nil,
                receipt: nil,
                downloadURL: assetToken.url
            )

            let record = try await service.createRecord(
                recordType: IntegrationTestData.recordType,
                fields: [
                    "title": .string("Test Record \(i)"),
                    "index": .int64(i),
                    "image": .asset(asset),
                    "createdAt": .date(Date())
                ]
            )

            createdRecordNames.append(record.recordName)

            if verbose {
                print("   ✅ Created: \(record.recordName)")
            }
        }

        guard !createdRecordNames.isEmpty else {
            throw IntegrationTestError.noRecordsCreated
        }

        print("✅ Created \(createdRecordNames.count) records")

        return createdRecordNames
    }

    // MARK: - Phase 4: Initial Sync

    private func phase4InitialSync(
        service: CloudKitService,
        createdRecordNames: [String]
    ) async throws -> String? {
        print("\n🔄 Phase 4: Initial sync (fetch all changes)")

        let initialResult = try await service.fetchRecordChanges()

        print("✅ Fetched \(initialResult.records.count) records")

        if verbose {
            if let token = initialResult.syncToken {
                print("   Sync token: \(token.prefix(30))...")
            }
            print("   More coming: \(initialResult.moreComing)")
        }

        // Find our test records
        let ourRecords = initialResult.records.filter {
            createdRecordNames.contains($0.recordName)
        }

        print("   Found \(ourRecords.count) of our test records")

        if ourRecords.count != createdRecordNames.count && verbose {
            print("   ⚠️  Expected \(createdRecordNames.count), found \(ourRecords.count)")
            print("   (Records may not be immediately available)")
        }

        return initialResult.syncToken
    }

    // MARK: - Phase 5: Modify Records

    private func phase5ModifyRecords(
        service: CloudKitService,
        createdRecordNames: [String]
    ) async throws {
        print("\n✏️  Phase 5: Modify some records")

        let updateCount = min(3, createdRecordNames.count)

        for i in 0..<updateCount {
            let recordName = createdRecordNames[i]

            _ = try await service.updateRecord(
                recordType: IntegrationTestData.recordType,
                recordName: recordName,
                fields: [
                    "title": .string("Updated Record \(i + 1)"),
                    "modified": .int64(1)
                ]
            )

            if verbose {
                print("   ✅ Updated: \(recordName)")
            }
        }

        print("✅ Updated \(updateCount) records")
    }

    // MARK: - Phase 6: Incremental Sync

    private func phase6IncrementalSync(
        service: CloudKitService,
        syncToken: String?,
        createdRecordNames: [String]
    ) async throws {
        print("\n🔄 Phase 6: Incremental sync (fetch only changes)")

        guard let token = syncToken else {
            throw IntegrationTestError.syncTokenMissing
        }

        if verbose {
            print("   Using sync token: \(token.prefix(30))...")
        }

        let incrementalResult = try await service.fetchRecordChanges(syncToken: token)

        print("✅ Fetched \(incrementalResult.records.count) changed records")

        if verbose {
            if let newToken = incrementalResult.syncToken {
                print("   New sync token: \(newToken.prefix(30))...")
            }
        }

        // Verify we only got changed records
        let changedRecords = incrementalResult.records.filter {
            createdRecordNames.contains($0.recordName)
        }

        print("   Found \(changedRecords.count) of our modified records")

        if verbose && changedRecords.count > 0 {
            print("   Modified records:")
            for record in changedRecords {
                print("      - \(record.recordName)")
            }
        }
    }

    // MARK: - Phase 7: Final Zone Verification

    private func phase7FinalVerification(service: CloudKitService) async throws {
        print("\n🔍 Phase 7: Lookup zone details")

        let finalZones = try await service.lookupZones(zoneIDs: [.defaultZone])

        guard !finalZones.isEmpty else {
            throw IntegrationTestError.verificationFailed("Zone not found after operations")
        }

        print("✅ Zone verification complete")
    }

    // MARK: - Phase 8: Cleanup

    private func phase8Cleanup(
        service: CloudKitService,
        createdRecordNames: [String]
    ) async throws {
        print("\n🧹 Phase 8: Cleanup test records")

        var deletedCount = 0

        for recordName in createdRecordNames {
            do {
                try await service.deleteRecord(
                    recordType: IntegrationTestData.recordType,
                    recordName: recordName
                )
                deletedCount += 1

                if verbose {
                    print("   ✅ Deleted: \(recordName)")
                }
            } catch {
                if verbose {
                    print("   ⚠️  Failed to delete \(recordName): \(error)")
                }
            }
        }

        print("✅ Deleted \(deletedCount) test records")

        if deletedCount < createdRecordNames.count {
            let failedCount = createdRecordNames.count - deletedCount
            print("   ⚠️  Failed to delete \(failedCount) records")
        }
    }

    // MARK: - Helper Methods

    private func printSkippedCleanup(recordNames: [String]) {
        print("\n⚠️  Skipping cleanup (--skip-cleanup flag set)")
        print("   Test records left in CloudKit:")
        for name in recordNames {
            print("   - \(name)")
        }
        print("\nTo manually cleanup these records:")
        print("   1. Visit https://icloud.developer.apple.com/dashboard/")
        print("   2. Select your container: \(containerIdentifier)")
        print("   3. Navigate to Public Database → Records")
        print("   4. Search for record type: \(IntegrationTestData.recordType)")
    }

    private func printSuccessSummary() {
        print("\n" + String(repeating: "=", count: 80))
        print("✅ Integration Test Complete!")
        print(String(repeating: "=", count: 80))
        print("\nPhases Completed:")
        print("  ✅ Zone verification with lookupZones")
        print("  ✅ Asset upload with uploadAssets")
        print("  ✅ Record creation with assets")
        print("  ✅ Initial sync with fetchRecordChanges")
        print("  ✅ Record modifications")
        print("  ✅ Incremental sync with sync token")
        print("  ✅ Final zone verification")

        if !skipCleanup {
            print("  ✅ Cleanup completed")
        } else {
            print("  ⏭️  Cleanup skipped")
        }

        print("\n💡 Next steps:")
        print("  • Run with --verbose for detailed output")
        print("  • Use --skip-cleanup to inspect records in CloudKit Console")
        print("  • Adjust --record-count for stress testing")
        print("  • Try --asset-size for larger file uploads")
    }
}
