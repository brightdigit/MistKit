//
//  CloudKitStore+Assets.swift
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

#if canImport(CloudKit)
  internal import CloudKit
  internal import Foundation
  internal import MistDemoKit

  /// Result of a composed `assets/rereference`. The native CloudKit surface
  /// can't move asset metadata between records in one call — we fetch the
  /// source record, reuse its `CKAsset`, then save it onto the target
  /// record. The result records both the source and target.
  internal struct RereferenceResult: Sendable {
    internal let sourceRecordName: String
    internal let assetField: String
    internal let targetRecordName: String
    internal let targetAssetField: String
  }

  extension CloudKitStore {
    /// Upload `fileURL` as the `image` asset on a new Note record. Maps to
    /// `assets/upload` in the REST surface — native CloudKit does the
    /// upload inline as part of `database.save(_:)`.
    internal func uploadAssetNote(
      title: String,
      index: Int64,
      fileURL: URL
    ) async throws -> Note {
      try await createNote(title: title, index: index, imageURL: fileURL)
    }

    /// Re-reference an asset from one record onto another. Composed call:
    /// fetch the source record, pull its `CKAsset`, save the target with
    /// that same asset. Native CloudKit doesn't expose a single-call
    /// equivalent of the REST `assets/rereference` endpoint, hence the
    /// composition.
    internal func rereferenceAsset(
      sourceRecordName: String,
      assetField: String,
      targetRecordName: String,
      targetAssetField: String? = nil
    ) async throws -> RereferenceResult {
      let resolvedTargetField = targetAssetField ?? assetField

      let sourceID = CKRecord.ID(recordName: sourceRecordName)
      let sourceRecord = try await database.record(for: sourceID)
      guard let asset = sourceRecord[assetField] as? CKAsset else {
        throw CloudKitStoreError.unexpectedSaveResult
      }

      let targetID = CKRecord.ID(recordName: targetRecordName)
      let targetRecord = try await database.record(for: targetID)
      targetRecord[resolvedTargetField] = asset
      _ = try await database.save(targetRecord)

      return RereferenceResult(
        sourceRecordName: sourceRecordName,
        assetField: assetField,
        targetRecordName: targetRecordName,
        targetAssetField: resolvedTargetField
      )
    }
  }
#endif
