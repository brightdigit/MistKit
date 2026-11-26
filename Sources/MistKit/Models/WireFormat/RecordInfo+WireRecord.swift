//
//  RecordInfo+WireRecord.swift
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

extension RecordInfo {
  /// The record a wire record describes.
  ///
  /// ``WireRecord/clearedFields`` are dropped: a record has no cleared fields,
  /// only fields it has or hasn't.
  ///
  /// - Throws: ``ConversionError/recordMissingRecordName`` when the wire
  ///   record has no name.
  public init(_ wire: WireRecord) throws(ConversionError) {
    guard let recordName = wire.recordName else {
      throw .recordMissingRecordName
    }
    self.init(
      recordName: recordName,
      zoneID: wire.zoneID,
      recordType: wire.recordType,
      recordChangeTag: wire.recordChangeTag,
      fields: wire.fields,
      encryptedFields: wire.encryptedFields,
      created: wire.created,
      modified: wire.modified,
      deleted: wire.deleted
    )
  }
}
