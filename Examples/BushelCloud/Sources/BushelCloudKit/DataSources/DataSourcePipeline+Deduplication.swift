//
//  DataSourcePipeline+Deduplication.swift
//  BushelCloud
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

import BushelFoundation
import Foundation

// MARK: - Deduplication
extension DataSourcePipeline {
  /// Deduplicate restore images by build number, keeping the most complete record
  internal func deduplicateRestoreImages(_ images: [RestoreImageRecord]) -> [RestoreImageRecord] {
    var uniqueImages: [String: RestoreImageRecord] = [:]

    for image in images {
      let key = image.buildNumber

      if let existing = uniqueImages[key] {
        // Keep the record with more complete data
        uniqueImages[key] = mergeRestoreImages(existing, image)
      } else {
        uniqueImages[key] = image
      }
    }

    return Array(uniqueImages.values).sorted { $0.releaseDate > $1.releaseDate }
  }

  /// Merge two restore image records, preferring non-empty values
  ///
  /// This method handles backfilling missing data from different sources:
  /// - SHA-256 hashes from AppleDB fill in empty values from ipsw.me
  /// - File sizes and SHA-1 hashes are similarly backfilled
  /// - Signing status follows MESU authoritative rules
  internal func mergeRestoreImages(
    _ first: RestoreImageRecord,
    _ second: RestoreImageRecord
  ) -> RestoreImageRecord {
    var merged = first

    // Backfill missing hashes and file size from second record
    merged.sha256Hash = backfillValue(first: first.sha256Hash, second: second.sha256Hash)
    merged.sha1Hash = backfillValue(first: first.sha1Hash, second: second.sha1Hash)
    merged.fileSize = backfillFileSize(first: first.fileSize, second: second.fileSize)

    // Merge isSigned using priority rules
    merged.isSigned = mergeIsSignedStatus(first: first, second: second)

    // Combine notes
    merged.notes = combineNotes(first: first.notes, second: second.notes)

    return merged
  }

  private func backfillValue(first: String, second: String) -> String {
    if !second.isEmpty && first.isEmpty {
      return second
    }
    return first
  }

  private func backfillFileSize(first: Int, second: Int) -> Int {
    if second > 0 && first == 0 {
      return second
    }
    return first
  }

  private func mergeIsSignedStatus(
    first: RestoreImageRecord,
    second: RestoreImageRecord
  ) -> Bool? {
    // Define authoritative sources for signing status
    let authoritativeSources: Set<String> = ["mesu.apple.com", "tss.virtualbuddy.app"]

    // Priority 1: Authoritative sources (MESU or VirtualBuddy)
    if authoritativeSources.contains(first.source), let signed = first.isSigned {
      return signed
    }
    if authoritativeSources.contains(second.source), let signed = second.isSigned {
      return signed
    }

    // Priority 2: Most recent update timestamp
    return mergeIsSignedByTimestamp(
      firstSigned: first.isSigned,
      firstDate: first.sourceUpdatedAt,
      secondSigned: second.isSigned,
      secondDate: second.sourceUpdatedAt
    )
  }

  private func mergeIsSignedByTimestamp(
    firstSigned: Bool?,
    firstDate: Date?,
    secondSigned: Bool?,
    secondDate: Date?
  ) -> Bool? {
    // Both have dates - use the more recent one
    if let firstTimestamp = firstDate, let secondTimestamp = secondDate {
      if secondTimestamp > firstTimestamp {
        return secondSigned ?? firstSigned
      } else {
        return firstSigned ?? secondSigned
      }
    }

    // Only second has date
    if secondDate != nil {
      return secondSigned ?? firstSigned
    }

    // Only first has date
    if firstDate != nil {
      return firstSigned ?? secondSigned
    }

    // No dates - handle conflicting values
    return resolveConflictingSignedStatus(first: firstSigned, second: secondSigned)
  }

  private func resolveConflictingSignedStatus(first: Bool?, second: Bool?) -> Bool? {
    guard let firstValue = first, let secondValue = second else {
      return second ?? first
    }

    // Both have values - prefer false when they disagree
    return firstValue == secondValue ? firstValue : false
  }

  private func combineNotes(first: String?, second: String?) -> String? {
    guard let secondNotes = second, !secondNotes.isEmpty else {
      return first
    }

    if let firstNotes = first, !firstNotes.isEmpty {
      return "\(firstNotes); \(secondNotes)"
    }

    return secondNotes
  }

  /// Deduplicate Xcode versions by build number
  internal func deduplicateXcodeVersions(_ versions: [XcodeVersionRecord]) -> [XcodeVersionRecord] {
    var uniqueVersions: [String: XcodeVersionRecord] = [:]

    for version in versions {
      let key = version.buildNumber
      if uniqueVersions[key] == nil {
        uniqueVersions[key] = version
      }
    }

    return Array(uniqueVersions.values).sorted { $0.releaseDate > $1.releaseDate }
  }

  /// Deduplicate Swift versions by version number
  internal func deduplicateSwiftVersions(_ versions: [SwiftVersionRecord]) -> [SwiftVersionRecord] {
    var uniqueVersions: [String: SwiftVersionRecord] = [:]

    for version in versions {
      let key = version.version
      if uniqueVersions[key] == nil {
        uniqueVersions[key] = version
      }
    }

    return Array(uniqueVersions.values).sorted { $0.releaseDate > $1.releaseDate }
  }
}
