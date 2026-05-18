//
//  QuotaHint.swift
//  MistKit
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

/// Local-context diagnostic attached to `CloudKitError.quotaExceeded`.
///
/// CloudKit returns `QUOTA_EXCEEDED` (HTTP 413) for several distinct
/// conditions — per-record field-data limit, per-asset upload limit, and
/// per-app storage quota exhaustion — all under the same `serverErrorCode`.
/// When MistKit can identify a probable cause from the request that triggered
/// the error, it attaches the matching `QuotaHint` so the caller doesn't have
/// to reconstruct what happened from the server's free-form `reason` string.
///
/// A `nil` hint means MistKit either had no relevant local context or the
/// request didn't trip any known limit — most likely the user's iCloud quota
/// is exhausted.
public enum QuotaHint: Sendable, Equatable {
  /// A record in a `modifyRecords` batch had a JSON-encoded size larger than
  /// CloudKit's per-record limit (`CloudKitService.maxRecordDataBytes`).
  /// The asset blob is not counted here — it travels via the CDN.
  case recordExceedsSizeLimit(operationIndex: Int, encodedBytes: Int, maxBytes: Int)

  /// Asset data passed to `uploadAssets` / `uploadAssetData` was larger than
  /// CloudKit's per-asset upload limit (`CloudKitService.maxAssetUploadBytes`).
  case assetExceedsSizeLimit(dataBytes: Int, maxBytes: Int)

  /// Human-readable summary used in `CloudKitError.errorDescription`.
  public var description: String {
    switch self {
    case .recordExceedsSizeLimit(let index, let encoded, let max):
      return
        "operations[\(index)] encoded to \(encoded) bytes "
        + "(limit \(max) bytes / \(max / 1_024 / 1_024) MB)"
    case .assetExceedsSizeLimit(let data, let max):
      return
        "asset data was \(data) bytes "
        + "(limit \(max) bytes / \(max / 1_024 / 1_024) MB)"
    }
  }
}
