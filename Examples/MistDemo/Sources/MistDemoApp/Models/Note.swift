//
//  Note.swift
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

  /// Note record, mirroring the `Note` type defined in `schema.ckdb`:
  ///
  ///     RECORD TYPE Note (
  ///         "title" STRING    QUERYABLE SORTABLE SEARCHABLE,
  ///         "index" INT64     QUERYABLE SORTABLE,
  ///         "image" ASSET
  ///     );
  ///
  /// Created / modified timestamps come from CloudKit's system metadata
  /// (`CKRecord.creationDate` / `.modificationDate`), so there's no need
  /// for custom `createdAt` / `modified` schema fields.
  extension Note {
    internal init?(_ record: CKRecord) {
      guard record.recordType == Self.recordType else {
        return nil
      }
      self.init(
        id: record.recordID.recordName,
        title: record.typedValue(forField: Fields.title, as: String.self),
        index: record.typedValue(forField: Fields.index, as: NSNumber.self)?.int64Value,
        imageAssetURL: record.typedValue(forField: Fields.image, as: CKAsset.self)?.fileURL,
        modificationDate: record.modificationDate,
        creationDate: record.creationDate,
        recordChangeTag: record.recordChangeTag,
        creatorUserRecordName: record.creatorUserRecordID?.recordName
      )
    }
  }
#endif
