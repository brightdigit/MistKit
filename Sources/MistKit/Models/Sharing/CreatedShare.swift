//
//  CreatedShare.swift
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

public import Foundation

/// The result of creating a CloudKit share via ``CloudKitService/createShare``.
///
/// Carries the generated short GUID and invite URL alongside the root record
/// and share-specific metadata. Share keys stay here (and on ``ShareInfo``)
/// rather than on ``RecordInfo``, which models a plain record.
public struct CreatedShare: Sendable {
  // swift-format-ignore: NeverForceUnwrap
  /// Base URL for iCloud share invite links (`https://www.icloud.com/share`).
  ///
  /// Append a ``ShortGUID`` path component to build a full invite URL.
  public static let shareURLBase = URL(string: "https://www.icloud.com/share")!

  /// The short GUID CloudKit assigned to the share (and shared root).
  public let shortGUID: ShortGUID
  /// The iCloud share invite URL (`https://www.icloud.com/share/{shortGUID}`).
  public let shareURL: URL
  /// Share-specific keys lifted from the `cloudkit.share` record.
  public let share: ShareInfo
  /// The root record that was shared.
  public let rootRecord: RecordInfo
  /// The record name of the created `cloudkit.share` record.
  public let shareRecordName: String

  /// Initialize a created-share result.
  /// - Parameters:
  ///   - shortGUID: The short GUID CloudKit assigned.
  ///   - shareURL: The iCloud share invite URL.
  ///   - share: Share-specific keys from the `cloudkit.share` record.
  ///   - rootRecord: The root record that was shared.
  ///   - shareRecordName: The `cloudkit.share` record name.
  public init(
    shortGUID: ShortGUID,
    shareURL: URL,
    share: ShareInfo,
    rootRecord: RecordInfo,
    shareRecordName: String
  ) {
    self.shortGUID = shortGUID
    self.shareURL = shareURL
    self.share = share
    self.rootRecord = rootRecord
    self.shareRecordName = shareRecordName
  }

  /// Build the standard iCloud share invite URL for a short GUID value.
  public static func shareURL(forShortGUID shortGUID: ShortGUID) -> URL {
    shareURLBase.appendingPathComponent(shortGUID)
  }
}
