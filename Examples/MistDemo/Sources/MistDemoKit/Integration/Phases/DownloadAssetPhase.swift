//
//  DownloadAssetPhase.swift
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

/// Looks up a created record's `image` asset and downloads the CDN bytes,
/// checking the byte count against the asset's declared `size`.
///
/// Checksum verification is deliberately not requested: CloudKit's
/// `fileChecksum` is an opaque server-minted value, not a digest of the
/// plaintext, so it cannot be recomputed client-side.
internal struct DownloadAssetPhase: IntegrationPhase {
  internal typealias Input = CreatedRecordNames
  internal typealias Output = NoState

  internal static let title = "Download asset"
  internal static let emoji = "📥"
  internal static let apiName = "downloadAsset"

  internal func run(
    input: CreatedRecordNames, context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    guard let recordName = input.names.first else {
      throw IntegrationTestError.missingPhaseState("createdRecordNames")
    }

    let results = try await context.service.lookupRecords(
      recordNames: [recordName],
      database: context.database
    )
    guard case .success(let record)? = results.first else {
      throw IntegrationTestError.verificationFailed(
        "Lookup of '\(recordName)' did not return a record for asset download"
      )
    }
    guard case .asset(let asset) = record.fields["image"] else {
      throw IntegrationTestError.verificationFailed(
        "Record '\(recordName)' has no 'image' asset to download"
      )
    }

    if context.verbose {
      print("   Record: \(recordName)")
      print("   fileChecksum: \(asset.fileChecksum ?? "nil")")
      print("   downloadURL: \(asset.downloadURL ?? "nil")")
    }

    let data = try await asset.download()
    if let declaredSize = asset.size, Int64(data.count) != declaredSize {
      throw IntegrationTestError.verificationFailed(
        "Downloaded \(data.count) bytes but the asset declares \(declaredSize)"
      )
    }
    print("✅ Downloaded \(data.count) bytes")

    return NoState()
  }
}
