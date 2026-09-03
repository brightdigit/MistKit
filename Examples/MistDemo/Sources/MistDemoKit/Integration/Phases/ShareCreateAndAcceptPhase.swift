//
//  ShareCreateAndAcceptPhase.swift
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

/// Creates a share as the sharer (private DB), then resolves and accepts it
/// as the sharee (public + web-auth).
///
/// Requires `PhaseContext.shareeService` and `PhaseContext.shareeEmail`
/// (`CLOUDKIT_SHAREE_WEB_AUTH_TOKEN` / `CLOUDKIT_SHAREE_EMAIL`). Fails early
/// when both web-auth tokens resolve to the same `users/caller` record name.
/// Self-cleaning: deletes the share root and zone afterward.
internal struct ShareCreateAndAcceptPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Create share and accept as sharee"
  internal static let emoji = "🤝"
  internal static let apiName = "createShare+acceptShares"

  internal func run(input: NoState, context: PhaseContext) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    guard let shareeService = context.shareeService,
      let shareeEmail = context.shareeEmail,
      !shareeEmail.isEmpty
    else {
      throw IntegrationTestError.missingShareeCredentials
    }

    // Distinct Apple IDs are required: inviting yourself is not a useful
    // create→accept roundtrip. Compare users/caller record names up front.
    let sharerIdentity: UserInfo
    do {
      sharerIdentity = try await context.service.fetchCaller()
    } catch {
      throw IntegrationTestError.verificationFailed(
        "sharer users/caller failed: \(error)"
      )
    }
    let shareeIdentity: UserInfo
    do {
      shareeIdentity = try await shareeService.fetchCaller()
    } catch {
      throw IntegrationTestError.verificationFailed(
        "sharee users/caller failed: \(error)"
      )
    }
    if sharerIdentity.userRecordName == shareeIdentity.userRecordName {
      throw IntegrationTestError.shareeSameAsSharer(
        userRecordName: sharerIdentity.userRecordName
      )
    }
    if context.verbose {
      print("   Sharer userRecordName: \(sharerIdentity.userRecordName)")
      print("   Sharee userRecordName: \(shareeIdentity.userRecordName)")
    }

    let zoneName = "mistkit-share-\(UUID().uuidString.lowercased())"
    let zoneID = ZoneID(zoneName: zoneName)
    let rootRecordName = "mistkit-share-root-\(UUID().uuidString.lowercased())"

    _ = try await context.service.createZone(
      zoneName: zoneName,
      database: context.database
    )
    if context.verbose {
      print("   ✅ Created zone: \(zoneName)")
    }

    do {
      let created = try await context.service.createShare(
        rootRecordType: MistDemoConfig.recordType,
        rootRecordName: RecordName(rootRecordName),
        rootFields: [
          "title": .string("Share roundtrip"),
          "index": .int64(0),
        ],
        zoneID: zoneID,
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

      print("✅ Created share \(created.shortGUID)")
      if context.verbose {
        print("   Share URL: \(created.shareURL.absoluteString)")
      }

      let shortGUID = ShortGUIDDictionary(
        value: created.shortGUID,
        shouldFetchRootRecord: true
      )

      let resolved = try await shareeService.resolveShares([shortGUID])
      guard let resolveInfo = resolved.first else {
        throw IntegrationTestError.shareResolveEmpty
      }
      if context.verbose {
        print("   Resolved root: \(resolveInfo.rootRecordName ?? "-")")
        print(
          "   Resolve status: \(resolveInfo.participantStatus?.rawValue ?? "-")"
        )
      }

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

      try await cleanup(
        sharer: context.service,
        database: context.database,
        zoneID: zoneID,
        rootRecordName: created.rootRecord.recordName,
        shareRecordName: created.shareRecordName,
        verbose: context.verbose
      )
    } catch {
      try? await cleanup(
        sharer: context.service,
        database: context.database,
        zoneID: zoneID,
        rootRecordName: RecordName(rootRecordName),
        shareRecordName: nil,
        verbose: context.verbose
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
    verbose: Bool
  ) async throws {
    var ops = [
      RecordOperation(
        operationType: .forceDelete,
        recordType: MistDemoConfig.recordType,
        recordName: rootRecordName
      )
    ]
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
        print("   ✅ Deleted share root in zone \(zoneID.zoneName)")
      }
    } catch {
      if verbose {
        print("   ⚠️  Share record cleanup failed: \(error)")
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
