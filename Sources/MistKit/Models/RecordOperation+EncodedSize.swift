//
//  RecordOperation+EncodedSize.swift
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
internal import MistKitOpenAPI

extension RecordOperation {
  /// Size in bytes of this operation's record envelope when JSON-encoded for
  /// the wire.
  ///
  /// Compare against ``CloudKitService/maxRecordDataBytes`` (1 MB) to
  /// pre-flight CloudKit's per-record data limit before calling
  /// ``CloudKitService/modifyRecords(_:atomic:database:)``. Delete operations
  /// carry a small envelope (record name, record type, empty fields) so they
  /// report a tiny but non-zero size.
  ///
  /// Asset field values carry only their reference metadata here; the binary
  /// blob travels via the CDN and is bounded separately by
  /// ``CloudKitService/maxAssetUploadBytes``.
  public func encodedRecordSize() throws -> Int {
    let apiOperation = try Components.Schemas.RecordOperation(from: self)
    guard let record = apiOperation.record else {
      return 0
    }
    return try JSONEncoder.shared.encode(record).count
  }
}
