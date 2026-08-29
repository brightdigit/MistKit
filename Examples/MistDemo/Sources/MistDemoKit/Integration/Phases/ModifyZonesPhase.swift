//
//  ModifyZonesPhase.swift
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

/// Exercises `modifyZones` end-to-end: create a uniquely-named test zone,
/// verify it via `lookupZones`, then delete it. Cleanup runs even on
/// verification failure so we don't leave stray zones behind.
internal struct ModifyZonesPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Modify zones (create + verify + delete)"
  internal static let emoji = "🧱"
  internal static let apiName = "modifyZones"

  private static func reportVerifiedZone(_ zone: ZoneInfo) {
    print("   ✅ Verified zone via lookupZones")
    if let syncToken = zone.syncToken {
      print("     Sync Token: \(syncToken)")
    }
    if let atomic = zone.atomic {
      print("     Atomic: \(atomic)")
    }
  }

  private static func describe(_ failure: ZoneOperationFailure) -> String {
    "(\(failure.serverErrorCode.rawValue))" + (failure.reason.map { ": \($0)" } ?? "")
  }

  internal func run(
    input: NoState,
    context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    let suffix = UUID().uuidString.prefix(8)
    let zoneName = "MistDemoIntegrationZone-\(suffix)"
    let zoneID = ZoneID(zoneName: zoneName, ownerName: nil)

    do {
      try await createAndVerify(zoneID: zoneID, zoneName: zoneName, context: context)
      try await cleanup(zoneID: zoneID, context: context)
      if context.verbose {
        print("   ✅ Deleted zone: \(zoneName)")
      }
    } catch let error as IntegrationTestError {
      throw error
    } catch {
      try? await cleanup(zoneID: zoneID, context: context)
      throw IntegrationTestError.verificationFailed(
        "modifyZones round-trip failed: \(error.localizedDescription)"
      )
    }

    print("✅ Round-tripped zone create/verify/delete")
    return NoState()
  }

  /// Creates the zone and confirms `lookupZones` reports it back.
  ///
  /// `modifyZones` returns a per-zone `[ZoneChangeResult]`, so a rejected
  /// create is reported inline in a 200 response rather than thrown — check
  /// `failures` explicitly instead of discarding the results.
  private func createAndVerify(
    zoneID: ZoneID,
    zoneName: String,
    context: PhaseContext
  ) async throws {
    let created = try await context.service.modifyZones(
      [.create(zoneID)],
      database: context.database
    )
    if let failure = created.failures.first {
      throw IntegrationTestError.verificationFailed(
        "creating zone '\(zoneName)' failed \(Self.describe(failure))"
      )
    }
    if context.verbose {
      print("   ✅ Created zone: \(zoneName)")
    }

    let lookedUp = try await context.service.lookupZones(
      zoneIDs: [zoneID],
      database: context.database
    )
    guard let verifiedZone = lookedUp.first(where: { $0.zoneName == zoneName }) else {
      try await cleanup(zoneID: zoneID, context: context)
      throw IntegrationTestError.verificationFailed(
        "created zone '\(zoneName)' not returned by lookupZones"
      )
    }
    if context.verbose {
      Self.reportVerifiedZone(verifiedZone)
    }
  }

  private func cleanup(
    zoneID: ZoneID,
    context: PhaseContext
  ) async throws {
    let results = try await context.service.modifyZones(
      [.delete(zoneID)],
      database: context.database
    )
    for result in results {
      _ = try result.get()
    }
  }
}
