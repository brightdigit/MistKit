//
//  ZoneRoundtripPhase.swift
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

/// Create and immediately delete a uniquely-named zone, exercising both
/// ``CloudKitService/createZone(zoneName:ownerRecordName:database:)`` and
/// ``CloudKitService/deleteZone(zoneName:ownerRecordName:database:)`` in
/// a single self-cleaning phase. CloudKit only allows custom zones on the
/// private and shared databases.
internal struct ZoneRoundtripPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Create and delete a zone"
  internal static let emoji = "🌀"
  internal static let apiName = "createZone+deleteZone"

  internal func run(input: NoState, context: PhaseContext) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    let zoneName = "mistkit-itest-\(UUID().uuidString.lowercased())"

    let created = try await context.service.createZone(
      zoneName: zoneName,
      database: context.database
    )
    if context.verbose {
      print("   ✅ Created zone: \(created.zoneName)")
    }

    try await context.service.deleteZone(
      zoneName: zoneName,
      database: context.database
    )
    if context.verbose {
      print("   ✅ Deleted zone: \(zoneName)")
    }

    print("✅ Roundtrip succeeded for zone '\(zoneName)'")

    return NoState()
  }
}
