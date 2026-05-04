//
//  IntegrationTestRunner+SyncPhases.swift
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

extension IntegrationTestRunner {
  // MARK: - Phase 7: Initial Sync

  func phase7InitialSync(
    service: CloudKitService,
    createdRecordNames: [String]
  ) async throws -> String? {
    print("\n🔄 Phase 7: Initial sync (fetch all changes)")

    do {
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
    } catch {
      print(
        "⚠️  fetchRecordChanges failed (non-fatal, change tracking requires custom zones): \(error)")
      return nil
    }
  }

  // MARK: - Phase 8: Modify Records

  func phase8ModifyRecords(
    service: CloudKitService,
    createdRecordNames: [String]
  ) async throws {
    print("\n✏️  Phase 8: Modify some records")

    let recordsToUpdate = Array(createdRecordNames.prefix(min(3, createdRecordNames.count)))

    let operations = recordsToUpdate.enumerated().map { offset, recordName in
      RecordOperation(
        operationType: .forceReplace,
        recordType: IntegrationTestData.recordType,
        recordName: recordName,
        fields: [
          "title": .string("Updated Record \(offset + 1)"),
          "modified": .int64(1),
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

  func phase9IncrementalSync(
    service: CloudKitService,
    syncToken: String?,
    createdRecordNames: [String]
  ) async throws {
    print("\n🔄 Phase 9: Incremental sync (fetch only changes)")

    guard let token = syncToken else {
      print(
        "⚠️  No sync token available — skipping incremental sync (change tracking requires custom zones)"
      )
      return
    }

    if verbose {
      print("   Using sync token: \(token.prefix(30))...")
    }

    do {
      let incrementalResult = try await service.fetchRecordChanges(syncToken: token)

      print("✅ Fetched \(incrementalResult.records.count) changed records")

      if verbose, let newToken = incrementalResult.syncToken {
        print("   New sync token: \(newToken.prefix(30))...")
      }

      let changedRecords = incrementalResult.records.filter {
        createdRecordNames.contains($0.recordName)
      }
      print("   Found \(changedRecords.count) of our modified records")

      if verbose && !changedRecords.isEmpty {
        print("   Modified records:")
        for record in changedRecords {
          print("      - \(record.recordName)")
        }
      }
    } catch {
      print("⚠️  fetchRecordChanges (incremental) failed (non-fatal): \(error)")
    }
  }

  // MARK: - Phase 10: Final Zone Verification

  func phase10FinalVerification(service: CloudKitService) async throws {
    print("\n🔍 Phase 10: Final zone verification")

    let finalZones = try await service.lookupZones(zoneIDs: [.defaultZone])

    guard !finalZones.isEmpty else {
      throw IntegrationTestError.verificationFailed("Zone not found after operations")
    }

    print("✅ Zone verification complete")
  }

  // MARK: - Phase 11: Cleanup

  func phase11Cleanup(
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
  func phaseFetchCurrentUser(service: CloudKitService) async throws -> UserInfo {
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

  func phaseDiscoverUserIdentities(
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
}
