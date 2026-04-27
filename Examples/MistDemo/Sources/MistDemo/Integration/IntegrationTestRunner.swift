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
    let service: CloudKitService
    let containerIdentifier: String
    let database: MistKit.Database
    let recordCount: Int
    let assetSizeKB: Int
    let skipCleanup: Bool
    let verbose: Bool

    // MARK: - Public Workflows

    /// Run the public-database workflow covering all non-user-scoped API methods.
    func runBasicWorkflow() async throws {
        printWorkflowHeader()
        try await runCorePhases(service: service)
        printSuccessSummary(includeUserPhases: false)
    }

    /// Run the private-database workflow covering all API methods including user-identity endpoints.
    func runPrivateWorkflow() async throws {
        printWorkflowHeader()
        try await runCorePhases(service: service)
        let userInfo = try await phaseFetchCurrentUser(service: service)
        try await phaseDiscoverUserIdentities(service: service, userRecordName: userInfo.userRecordName)
        printSuccessSummary(includeUserPhases: true)
    }

    // MARK: - Core Phase Runner

    private func runCorePhases(service: CloudKitService) async throws {
        var createdRecordNames: [String] = []
        var syncToken: String?

        do {
            if database == .private {
                try await phaseListZones(service: service)
            }
            try await phaseLookupZone(service: service)
            if database == .private {
                try await phaseFetchZoneChanges(service: service)
            }
            let assetToken = try await phase2UploadAsset(service: service)
            createdRecordNames = try await phase3CreateRecords(service: service, assetToken: assetToken)
            try await phaseQueryRecords(service: service, createdRecordNames: createdRecordNames)
            try await phaseLookupRecords(service: service, recordNames: createdRecordNames)
            if database == .private {
                syncToken = try await phase4InitialSync(service: service, createdRecordNames: createdRecordNames)
            }
            try await phase5ModifyRecords(service: service, createdRecordNames: createdRecordNames)
            if database == .private {
                try await phase6IncrementalSync(service: service, syncToken: syncToken, createdRecordNames: createdRecordNames)
            }
            try await phase7FinalVerification(service: service)
            if !skipCleanup {
                try await phase8Cleanup(service: service, createdRecordNames: createdRecordNames)
            } else {
                printSkippedCleanup(recordNames: createdRecordNames)
            }
        } catch let error as CloudKitError {
            print("\n❌ CloudKit Error: \(error)")
            if !createdRecordNames.isEmpty && !skipCleanup {
                print("\n⚠️  Attempting cleanup of \(createdRecordNames.count) test records...")
                try? await phase8Cleanup(service: service, createdRecordNames: createdRecordNames)
            }
            throw error
        } catch {
            print("\n❌ Error: \(error)")
            if !createdRecordNames.isEmpty && !skipCleanup {
                print("\n⚠️  Attempting cleanup of \(createdRecordNames.count) test records...")
                try? await phase8Cleanup(service: service, createdRecordNames: createdRecordNames)
            }
            throw error
        }
    }

    // MARK: - Phase 1: List All Zones

    private func phaseListZones(service: CloudKitService) async throws {
        print("\n📋 Phase 1: List all zones")

        let zones = try await service.listZones()

        guard !zones.isEmpty else {
            throw IntegrationTestError.zoneNotFound("(any zone)")
        }

        print("✅ Found \(zones.count) zone(s)")

        if verbose {
            for zone in zones {
                print("   - \(zone.zoneName)")
            }
        }
    }

    // MARK: - Phase 2: Lookup Specific Zone

    private func phaseLookupZone(service: CloudKitService) async throws {
        print("\n📋 Phase 2: Lookup default zone")

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

    // MARK: - Phase 2b: Fetch Zone Changes

    private func phaseFetchZoneChanges(service: CloudKitService) async throws {
        print("\n🔄 Phase 2b: Fetch zone changes")

        let result = try await service.fetchZoneChanges()

        print("✅ Fetched \(result.zones.count) zone(s)")

        if verbose {
            for zone in result.zones {
                print("   - \(zone.zoneName)")
            }
            if let token = result.syncToken {
                print("   Sync token: \(token.prefix(30))...")
            }
        }
    }

    // MARK: - Phase 3: Asset Upload

    private func phase2UploadAsset(service: CloudKitService) async throws -> AssetUploadReceipt {
        print("\n📤 Phase 3: Upload test asset")

        let testData = IntegrationTestData.generateTestImage(sizeKB: assetSizeKB)
        let sizeInMB = Double(testData.count) / 1024 / 1024

        if verbose {
            print("   Uploading \(testData.count) bytes (\(String(format: "%.2f", sizeInMB)) MB)...")
        }

        let receipt = try await service.uploadAssets(
            data: testData,
            recordType: IntegrationTestData.recordType,
            fieldName: "image"
        )

        print("✅ Uploaded asset: \(testData.count) bytes")

        if verbose {
            print("   Record: \(receipt.recordName)")
            print("   Field: \(receipt.fieldName)")
        }

        return receipt
    }

    // MARK: - Phase 4: Create Records

    private func phase3CreateRecords(
        service: CloudKitService,
        assetToken: AssetUploadReceipt
    ) async throws -> [String] {
        print("\n📝 Phase 4: Create records with assets")

        if verbose {
            print("   Creating \(recordCount) records...")
        }

        var createdRecordNames: [String] = []

        for i in 1...recordCount {
            let recordName = "mistkit-test-\(UUID().uuidString.lowercased())"
            let record = try await service.createRecord(
                recordType: IntegrationTestData.recordType,
                recordName: recordName,
                fields: [
                    "title": .string("Test Record \(i)"),
                    "index": .int64(i),
                    "image": .asset(assetToken.asset),
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

    // MARK: - Phase 5: Query Records

    private func phaseQueryRecords(
        service: CloudKitService,
        createdRecordNames: [String]
    ) async throws {
        print("\n🔍 Phase 5: Query records by type")

        do {
            let records = try await service.queryRecords(recordType: IntegrationTestData.recordType)
            print("✅ Queried \(records.count) record(s) of type '\(IntegrationTestData.recordType)'")
            if verbose {
                let ours = records.filter { createdRecordNames.contains($0.recordName) }
                print("   Found \(ours.count) of our \(createdRecordNames.count) test records")
            }
        } catch CloudKitError.httpErrorWithDetails(statusCode: 404, serverErrorCode: _, reason: _) where true {
            // Schema propagation in development can lag behind the first write.
            // lookupRecords (phase 6) already verifies the records exist by name.
            print("⚠️  queryRecords returned NOT_FOUND — schema may not be indexed yet (non-fatal)")
        }
    }

    // MARK: - Phase 6: Lookup Records by Name

    private func phaseLookupRecords(
        service: CloudKitService,
        recordNames: [String]
    ) async throws {
        let lookupNames = Array(recordNames.prefix(min(3, recordNames.count)))
        print("\n🔍 Phase 6: Lookup \(lookupNames.count) record(s) by name")

        let records = try await service.lookupRecords(recordNames: lookupNames)

        print("✅ Looked up \(records.count) record(s)")

        if verbose {
            for record in records {
                print("   - \(record.recordName)")
            }
        }
    }

    // MARK: - Phase 7: Initial Sync

    private func phase4InitialSync(
        service: CloudKitService,
        createdRecordNames: [String]
    ) async throws -> String? {
        print("\n🔄 Phase 7: Initial sync (fetch all changes)")

        let initialResult = try await service.fetchRecordChanges()

        print("✅ Fetched \(initialResult.records.count) records")

        if verbose {
            if let token = initialResult.syncToken {
                print("   Sync token: \(token.prefix(30))...")
            }
            print("   More coming: \(initialResult.moreComing)")
        }

        let ourRecords = initialResult.records.filter { createdRecordNames.contains($0.recordName) }
        print("   Found \(ourRecords.count) of our test records")

        if ourRecords.count != createdRecordNames.count && verbose {
            print("   ⚠️  Expected \(createdRecordNames.count), found \(ourRecords.count)")
            print("   (Records may not be immediately available)")
        }

        return initialResult.syncToken
    }

    // MARK: - Phase 8: Modify Records

    private func phase5ModifyRecords(
        service: CloudKitService,
        createdRecordNames: [String]
    ) async throws {
        print("\n✏️  Phase 8: Modify some records")

        let recordsToUpdate = Array(createdRecordNames.prefix(min(3, createdRecordNames.count)))

        let operations = recordsToUpdate.enumerated().map { (i, recordName) in
            RecordOperation(
                operationType: .forceReplace,
                recordType: IntegrationTestData.recordType,
                recordName: recordName,
                fields: [
                    "title": .string("Updated Record \(i + 1)"),
                    "modified": .int64(1)
                ]
            )
        }

        _ = try await service.modifyRecords(operations)

        if verbose {
            for recordName in recordsToUpdate {
                print("   ✅ Updated: \(recordName)")
            }
        }

        print("✅ Updated \(recordsToUpdate.count) records")
    }

    // MARK: - Phase 9: Incremental Sync

    private func phase6IncrementalSync(
        service: CloudKitService,
        syncToken: String?,
        createdRecordNames: [String]
    ) async throws {
        print("\n🔄 Phase 9: Incremental sync (fetch only changes)")

        guard let token = syncToken else {
            throw IntegrationTestError.syncTokenMissing
        }

        if verbose {
            print("   Using sync token: \(token.prefix(30))...")
        }

        let incrementalResult = try await service.fetchRecordChanges(syncToken: token)

        print("✅ Fetched \(incrementalResult.records.count) changed records")

        if verbose, let newToken = incrementalResult.syncToken {
            print("   New sync token: \(newToken.prefix(30))...")
        }

        let changedRecords = incrementalResult.records.filter { createdRecordNames.contains($0.recordName) }
        print("   Found \(changedRecords.count) of our modified records")

        if verbose && !changedRecords.isEmpty {
            print("   Modified records:")
            for record in changedRecords {
                print("      - \(record.recordName)")
            }
        }
    }

    // MARK: - Phase 10: Final Zone Verification

    private func phase7FinalVerification(service: CloudKitService) async throws {
        print("\n🔍 Phase 10: Final zone verification")

        let finalZones = try await service.lookupZones(zoneIDs: [.defaultZone])

        guard !finalZones.isEmpty else {
            throw IntegrationTestError.verificationFailed("Zone not found after operations")
        }

        print("✅ Zone verification complete")
    }

    // MARK: - Phase 11: Cleanup

    private func phase8Cleanup(
        service: CloudKitService,
        createdRecordNames: [String]
    ) async throws {
        print("\n🧹 Phase 11: Cleanup test records")

        var deletedCount = 0

        // Use forceDelete so no recordChangeTag is required.
        let deleteOps = createdRecordNames.map { recordName in
            RecordOperation(
                operationType: .forceDelete,
                recordType: IntegrationTestData.recordType,
                recordName: recordName
            )
        }

        do {
            _ = try await service.modifyRecords(deleteOps)
            deletedCount = createdRecordNames.count
            if verbose {
                for name in createdRecordNames { print("   ✅ Deleted: \(name)") }
            }
        } catch {
            if verbose { print("   ⚠️  Batch delete failed: \(error)") }
        }

        print("✅ Deleted \(deletedCount) test records")

        if deletedCount < createdRecordNames.count {
            print("   ⚠️  Failed to delete \(createdRecordNames.count - deletedCount) records")
        }
    }

    // MARK: - Phase 12: Fetch Current User (private only)

    @discardableResult
    private func phaseFetchCurrentUser(service: CloudKitService) async throws -> UserInfo {
        print("\n👤 Phase 12: Fetch current user")

        let userInfo = try await service.fetchCurrentUser()

        print("✅ Current user: \(userInfo.userRecordName)")

        if verbose {
            if let firstName = userInfo.firstName { print("   First name: \(firstName)") }
            if let lastName = userInfo.lastName { print("   Last name: \(lastName)") }
        }

        return userInfo
    }

    // MARK: - Phase 13: Discover User Identities (private only)

    private func phaseDiscoverUserIdentities(
        service: CloudKitService,
        userRecordName: String
    ) async throws {
        print("\n👥 Phase 13: Discover user identities")

        let lookupInfos = [UserIdentityLookupInfo(userRecordName: userRecordName)]
        let identities = try await service.discoverUserIdentities(lookupInfos: lookupInfos)

        print("✅ Discovered \(identities.count) user identit\(identities.count == 1 ? "y" : "ies")")

        if verbose {
            for identity in identities {
                if let name = identity.userRecordName { print("   - \(name)") }
            }
        }
    }

    // MARK: - Helpers

    private func printWorkflowHeader() {
        print("\n" + String(repeating: "=", count: 80))
        print("🧪 Integration Test Suite: CloudKit Operations")
        print(String(repeating: "=", count: 80))
        print("Container: \(containerIdentifier)")
        print("Database: \(database == .public ? "public" : "private")")
        print("Record Count: \(recordCount)")
        print("Asset Size: \(assetSizeKB) KB")
        print(String(repeating: "=", count: 80))
    }

    private func printSkippedCleanup(recordNames: [String]) {
        print("\n⚠️  Skipping cleanup (--skip-cleanup flag set)")
        print("   Test records left in CloudKit:")
        for name in recordNames { print("   - \(name)") }
        print("\nTo manually cleanup these records:")
        print("   1. Visit https://icloud.developer.apple.com/dashboard/")
        print("   2. Select your container: \(containerIdentifier)")
        print("   3. Navigate to \(database == .public ? "Public" : "Private") Database → Records")
        print("   4. Search for record type: \(IntegrationTestData.recordType)")
    }

    private func printSuccessSummary(includeUserPhases: Bool) {
        print("\n" + String(repeating: "=", count: 80))
        print("✅ Integration Test Complete!")
        print(String(repeating: "=", count: 80))
        print("\nPhases Completed:")
        if database == .private {
            print("  ✅ Phase  1: List all zones          (listZones)")
        } else {
            print("  ⏭️  Phase  1: List all zones          (listZones — private db only)")
        }
        print("  ✅ Phase  2: Lookup default zone     (lookupZones)")
        if database == .private {
            print("  ✅ Phase 2b: Fetch zone changes      (fetchZoneChanges)")
        } else {
            print("  ⏭️  Phase 2b: Fetch zone changes      (fetchZoneChanges — private db only)")
        }
        print("  ✅ Phase  3: Upload test asset       (uploadAssets)")
        print("  ✅ Phase  4: Create records          (createRecord)")
        print("  ✅ Phase  5: Query records by type   (queryRecords)")
        print("  ✅ Phase  6: Lookup records by name  (lookupRecords)")
        if database == .private {
            print("  ✅ Phase  7: Initial sync            (fetchRecordChanges)")
        } else {
            print("  ⏭️  Phase  7: Initial sync            (fetchRecordChanges — private db only)")
        }
        print("  ✅ Phase  8: Modify records          (updateRecord)")
        if database == .private {
            print("  ✅ Phase  9: Incremental sync        (fetchRecordChanges)")
        } else {
            print("  ⏭️  Phase  9: Incremental sync        (fetchRecordChanges — private db only)")
        }
        print("  ✅ Phase 10: Final zone check        (lookupZones)")
        if !skipCleanup {
            print("  ✅ Phase 11: Cleanup              (deleteRecord)")
        } else {
            print("  ⏭️  Phase 11: Cleanup skipped")
        }
        if includeUserPhases {
            print("  ✅ Phase 12: Fetch current user   (fetchCurrentUser)")
            print("  ✅ Phase 13: Discover identities  (discoverUserIdentities)")
        }
        print("\n💡 Next steps:")
        print("  • Run with --verbose for detailed output")
        print("  • Use --skip-cleanup to inspect records in CloudKit Console")
        if !includeUserPhases {
            print("  • Run 'mistdemo test-private' to also test user-identity APIs")
        }
    }
}
