//
//  RereferenceAssetPhase.swift
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

/// Re-references an existing asset from one record onto a freshly-created
/// target record without re-uploading the bytes, then verifies the target
/// resolves to the same asset (`assets/rereference`).
internal struct RereferenceAssetPhase: IntegrationPhase {
  internal typealias Input = RereferenceAssetInput
  internal typealias Output = CreatedRecordNames

  internal static let title = "Rereference asset"
  internal static let emoji = "📎"
  internal static let apiName = "rereferenceAssets"

  /// Confirm the target record now references the same asset bytes.
  private static func verify(
    _ record: RecordInfo, expected: Asset, context: PhaseContext
  ) throws {
    guard case .asset(let targetAsset) = record.fields["image"] else {
      throw IntegrationTestError.verificationFailed(
        "Target record '\(record.recordName)' has no 'image' asset after re-reference"
      )
    }

    // Verify against the file checksum when available — it's the stable signal.
    // Signed CDN download URLs carry an expiry and aren't stable across calls,
    // so they're only a fallback when no checksum was echoed back.
    if let expectedChecksum = expected.fileChecksum {
      guard targetAsset.fileChecksum == expectedChecksum else {
        throw IntegrationTestError.verificationFailed(
          "Re-referenced asset on '\(record.recordName)' does not match the source "
            + "(fileChecksum: \(targetAsset.fileChecksum ?? "nil") vs \(expectedChecksum))"
        )
      }
    } else if let expectedURL = expected.downloadURL {
      guard targetAsset.downloadURL == expectedURL else {
        throw IntegrationTestError.verificationFailed(
          "Re-referenced asset on '\(record.recordName)' does not match the source "
            + "(downloadURL: \(targetAsset.downloadURL ?? "nil") vs \(expectedURL))"
        )
      }
    } else {
      throw IntegrationTestError.verificationFailed(
        "Expected asset for '\(record.recordName)' has no identifying field to verify against"
      )
    }

    if context.verbose {
      print("   Verified fileChecksum: \(targetAsset.fileChecksum ?? "nil")")
    }
  }

  internal func run(
    input: RereferenceAssetInput, context: PhaseContext
  ) async throws -> CreatedRecordNames {
    print("\n\(Self.emoji) \(Self.title)")

    guard let sourceRecordName = input.recordNames.first else {
      throw IntegrationTestError.missingPhaseState("createdRecordNames")
    }

    // A fresh target record with no image of its own, so the re-reference is
    // what attaches the asset.
    let targetRecordName = "mistkit-test-\(UUID().uuidString.lowercased())"
    _ = try await context.service.createRecord(
      recordType: MistDemoConfig.recordType,
      recordName: targetRecordName,
      fields: [
        "title": .string("Rereference Target"),
        "index": .int64(0),
      ],
      database: context.database
    )

    if context.verbose {
      print("   Source: \(sourceRecordName)")
      print("   Target: \(targetRecordName)")
    }

    let updated = try await context.service.rereferenceAsset(
      fromRecord: sourceRecordName,
      field: "image",
      toRecord: targetRecordName,
      field: "image",
      database: context.database
    )

    try Self.verify(updated, expected: input.receipt.asset, context: context)

    print("✅ Re-referenced asset onto \(targetRecordName)")

    // Track the target so cleanup removes it alongside the other records.
    return CreatedRecordNames(input.recordNames + [targetRecordName])
  }
}
