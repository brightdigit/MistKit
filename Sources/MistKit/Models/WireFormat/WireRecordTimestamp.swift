//
//  WireRecordTimestamp.swift
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

internal import Foundation

/// A `created` / `modified` dictionary in CloudKit Web Services JSON:
/// `{"timestamp": …, "userRecordName": …}`, the timestamp in whole
/// milliseconds since 1970.
internal struct WireRecordTimestamp: Encodable {
  private enum CodingKeys: String, CodingKey {
    case timestamp
    case userRecordName
  }

  internal let stamp: RecordTimestamp

  internal init(_ stamp: RecordTimestamp) {
    self.stamp = stamp
  }

  internal func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let date = stamp.timestamp {
      let milliseconds = (date.timeIntervalSince1970 * 1_000).rounded()
      if let whole = Int64(exactly: milliseconds) {
        try container.encode(whole, forKey: .timestamp)
      } else {
        try container.encode(milliseconds, forKey: .timestamp)
      }
    }
    try container.encodeIfPresent(stamp.userRecordName, forKey: .userRecordName)
  }
}
