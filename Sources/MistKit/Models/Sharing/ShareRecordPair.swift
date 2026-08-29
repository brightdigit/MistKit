//
//  ShareRecordPair.swift
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

internal import MistKitOpenAPI

/// A `cloudkit.share` record together with its share-specific keys.
///
/// ``record`` is the ordinary record dictionary; ``info`` is the share
/// metadata lifted by ``ShareInfo``. Both are required — a share payload
/// that cannot produce ``ShareInfo`` is ``ConversionError/shareIncomplete``.
public struct ShareRecordPair: Sendable {
  /// The `cloudkit.share` record as a plain ``RecordInfo``.
  public let record: RecordInfo
  /// Share-specific keys lifted from the same wire payload.
  public let info: ShareInfo

  /// Initialize a share record pair.
  /// - Parameters:
  ///   - record: The `cloudkit.share` record.
  ///   - info: Share-specific keys from that record.
  public init(record: RecordInfo, info: ShareInfo) {
    self.record = record
    self.info = info
  }

  /// Lift a share record and its share keys from a record response.
  /// - Parameter schema: The wire `cloudkit.share` record.
  /// - Throws: ``ConversionError`` when the record cannot be converted or
  ///   the share key set is incomplete.
  internal init(from schema: Components.Schemas.RecordResponse) throws(ConversionError) {
    self.record = try RecordInfo(from: schema)
    guard let info = ShareInfo(from: schema) else {
      try ConversionError.shareIncomplete.reportAndThrow()
    }
    self.info = info
  }
}
