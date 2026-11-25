//
//  RecordOperation+Saving.swift
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

extension RecordOperation {
  /// An operation that saves `record` as it is.
  ///
  /// An `update` guarded by the record's `recordChangeTag`, so a record
  /// changed elsewhere comes back as `CONFLICT`, or a `create` when it has no
  /// change tag. Every set field is written. A record without a type (a
  /// tombstone) is written with an empty type.
  ///
  /// - Parameter record: The record to save.
  /// - Returns: The operation.
  public static func saving(_ record: RecordInfo) -> RecordOperation {
    RecordOperation(
      operationType: record.recordChangeTag == nil ? .create : .update,
      recordType: record.recordType ?? "",
      recordName: record.recordName,
      fields: record.fields,
      recordChangeTag: record.recordChangeTag
    )
  }
}
