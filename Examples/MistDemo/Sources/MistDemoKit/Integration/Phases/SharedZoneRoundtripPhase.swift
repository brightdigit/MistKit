//
//  SharedZoneRoundtripPhase.swift
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

/// Live shared-zone write round-trip: sharer creates a custom zone and share,
/// sharee accepts, then sharee update/lookup/zone-changes and zone-scoped asset
/// upload on the **shared root** (`database: .shared`, `zoneID.ownerName` =
/// sharer's user record name). CloudKit does not allow sharees to create
/// arbitrary new top-level records in the zone (ACCESS_DENIED).
///
/// Self-cleaning. Requires the same sharee credentials as
/// ``ShareCreateAndAcceptPhase``.
internal struct SharedZoneRoundtripPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Shared-zone CRUD and asset round-trip"
  internal static let emoji = "🔗"
  internal static let apiName = "shared zone write+uploadAssets"

  internal func run(input: NoState, context: PhaseContext) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    guard let shareeService = context.shareeService,
      let shareeEmail = context.shareeEmail,
      !shareeEmail.isEmpty
    else {
      throw IntegrationTestError.missingShareeCredentials
    }

    let sharerIdentity = try await context.service.fetchCaller()
    let shareeIdentity = try await shareeService.fetchCaller()
    if sharerIdentity.userRecordName == shareeIdentity.userRecordName {
      throw IntegrationTestError.shareeSameAsSharer(
        userRecordName: sharerIdentity.userRecordName
      )
    }

    let zoneName = "mistkit-shared-crud-\(UUID().uuidString.lowercased())"
    let privateZoneID = ZoneID(zoneName: zoneName)
    let rootRecordName = "mistkit-shared-root-\(UUID().uuidString.lowercased())"
    let sharedDatabase: MistKit.Database = .shared

    _ = try await context.service.createZone(
      zoneName: zoneName,
      database: context.database
    )
    if context.verbose {
      print("   ✅ Created zone: \(zoneName)")
      print("   Sharer: \(sharerIdentity.userRecordName)")
      print("   Sharee: \(shareeIdentity.userRecordName)")
    }

    var shareRecordName: RecordName?
    do {
      let created = try await context.service.createShare(
        rootRecordType: MistDemoConfig.recordType,
        rootRecordName: RecordName(rootRecordName),
        rootFields: [
          "title": .string("Shared zone root"),
          "index": .int64(0),
        ],
        zoneID: privateZoneID,
        publicPermission: .none,
        participants: [
          ShareParticipant(
            userIdentity: UserIdentity(
              lookupInfo: UserIdentityLookupInfo(emailAddress: shareeEmail)
            ),
            permission: .readWrite,
            type: .user,
            acceptanceStatus: .invited
          )
        ],
        database: context.database
      )
      shareRecordName = created.shareRecordName
      print("✅ Created share \(created.shortGUID)")

      let shortGUID = ShortGUIDDictionary(
        value: created.shortGUID,
        shouldFetchRootRecord: true
      )
      _ = try await shareeService.resolveShares([shortGUID])
      let accepted = try await shareeService.acceptShares([shortGUID])
      guard let acceptInfo = accepted.first else {
        throw IntegrationTestError.shareAcceptEmpty
      }
      if let status = acceptInfo.participantStatus, status == .invited {
        throw IntegrationTestError.shareStillInvited
      }
      print(
        "✅ Sharee accepted — status: "
          + "\(acceptInfo.participantStatus?.rawValue ?? "-")"
      )

      guard let acceptZoneID = acceptInfo.zoneID else {
        throw IntegrationTestError.verificationFailed(
          "acceptShares omitted zoneID — cannot address shared DB"
        )
      }
      // Pin owner to the sharer's users/caller name — accept may omit it.
      let sharedZoneID = ZoneID(
        zoneName: acceptZoneID.zoneName,
        ownerName: acceptZoneID.ownerName ?? sharerIdentity.userRecordName
      )
      let sharedRootName = acceptInfo.rootRecordName ?? created.rootRecord.recordName
      if context.verbose {
        print("   Shared zone: \(sharedZoneID.zoneName) owner \(sharedZoneID.ownerName ?? "-")")
        print("   Shared root: \(sharedRootName)")
      }

      guard let sharedRoot = acceptInfo.rootRecord else {
        throw IntegrationTestError.verificationFailed(
          "acceptShares omitted rootRecord (shouldFetchRootRecord was true)"
        )
      }

      // Sharees can modify records in the share, not create arbitrary new
      // top-level records in the zone (CloudKit returns ACCESS_DENIED).
      let updatedRoot = try await shareeService.updateRecord(
        recordType: MistDemoConfig.recordType,
        recordName: sharedRootName,
        fields: [
          "title": .string("Shared CRUD updated"),
          "index": .int64(42),
        ],
        recordChangeTag: sharedRoot.recordChangeTag,
        zoneID: sharedZoneID,
        database: sharedDatabase
      )
      if context.verbose {
        print("   ✅ Sharee updated shared root \(updatedRoot.recordName)")
      }

      guard updatedRoot.fields["title"] == .string("Shared CRUD updated"),
        updatedRoot.fields["index"] == .int64(42)
      else {
        throw IntegrationTestError.verificationFailed(
          "shared update did not round-trip title/index on \(sharedRootName)"
        )
      }
      if context.verbose {
        print("   ✅ Sharee read back updated fields from modify response")
      }

      let changeResult = try await shareeService.fetchRecordZoneChanges(
        zones: [ZoneChangesRequest(zoneID: sharedZoneID)],
        database: sharedDatabase
      )
      try ChangeTrackingVerification.requireNoZoneFailures(
        changeResult.failures,
        operation: "fetchRecordZoneChanges (shared)"
      )
      let changeNames = ChangeTrackingVerification.recordNames(in: changeResult.changes)
      if !changeNames.contains(sharedRootName.rawValue) {
        throw IntegrationTestError.verificationFailed(
          "shared changes/zone missing root \(sharedRootName); found \(changeNames.sorted())"
        )
      }

      // Asset must request an upload URL in the same zone as the update.
      let png = PNGData.generate(withSizeInKB: min(context.assetSizeKB, 8))
      let receipt = try await shareeService.uploadAssets(
        data: png,
        recordType: MistDemoConfig.recordType,
        fieldName: "image",
        recordName: sharedRootName,
        zoneID: sharedZoneID,
        database: sharedDatabase
      )
      let withAsset = try await shareeService.updateRecord(
        recordType: MistDemoConfig.recordType,
        recordName: sharedRootName,
        fields: [
          "title": .string("Shared asset"),
          "index": .int64(43),
          "image": .asset(receipt.asset),
        ],
        recordChangeTag: updatedRoot.recordChangeTag,
        zoneID: sharedZoneID,
        database: sharedDatabase
      )
      if context.verbose {
        print("   ✅ Sharee uploaded+attached asset on shared root")
      }

      _ = withAsset  // used for verification via successful update

      print("✅ Shared-zone CRUD and asset round-trip succeeded")

      try await cleanup(
        sharer: context.service,
        database: context.database,
        zoneID: privateZoneID,
        rootRecordName: sharedRootName,
        shareRecordName: created.shareRecordName,
        extraRecordNames: [],
        verbose: context.verbose,
        skipCleanup: context.skipCleanup
      )
    } catch {
      try? await cleanup(
        sharer: context.service,
        database: context.database,
        zoneID: privateZoneID,
        rootRecordName: RecordName(rootRecordName),
        shareRecordName: shareRecordName,
        extraRecordNames: [],
        verbose: context.verbose,
        skipCleanup: context.skipCleanup
      )
      throw error
    }

    return NoState()
  }

  private func cleanup(
    sharer: CloudKitService,
    database: MistKit.Database,
    zoneID: ZoneID,
    rootRecordName: RecordName,
    shareRecordName: RecordName?,
    extraRecordNames: [String],
    verbose: Bool,
    skipCleanup: Bool
  ) async throws {
    if skipCleanup {
      print("   ⏭️  Skipping shared-zone cleanup — inspect zone '\(zoneID.zoneName)'")
      return
    }

    var ops = [
      RecordOperation(
        operationType: .forceDelete,
        recordType: MistDemoConfig.recordType,
        recordName: rootRecordName
      )
    ]
    for name in extraRecordNames {
      ops.append(
        RecordOperation(
          operationType: .forceDelete,
          recordType: MistDemoConfig.recordType,
          recordName: RecordName(name)
        )
      )
    }
    if let shareRecordName {
      ops.append(
        RecordOperation(
          operationType: .forceDelete,
          recordType: ShareInfo.recordType,
          recordName: shareRecordName
        )
      )
    }
    do {
      _ = try await sharer.modifyRecords(ops, zoneID: zoneID, database: database)
      if verbose {
        print("   ✅ Deleted shared-zone records in \(zoneID.zoneName)")
      }
    } catch {
      if verbose {
        print("   ⚠️  Shared record cleanup failed: \(error)")
      }
    }

    do {
      try await sharer.deleteZone(zoneName: zoneID.zoneName, database: database)
      if verbose {
        print("   ✅ Deleted zone: \(zoneID.zoneName)")
      }
    } catch {
      if verbose {
        print("   ⚠️  Zone cleanup failed: \(error)")
      }
    }
  }
}
