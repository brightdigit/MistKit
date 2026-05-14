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

#if canImport(CloudKit) && !os(tvOS) && !os(watchOS)
  import CloudKit
  import Foundation

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
  internal struct Note: Identifiable, Hashable {
    /// Known field name constants for `Note` records.
    internal enum Fields {
      internal static let title = "title"
      internal static let index = "index"
      internal static let image = "image"
    }

    /// CloudKit record type identifier.
    internal static let recordType = "Note"

    internal let id: String
    internal let title: String?
    internal let index: Int64?
    internal let imageAssetURL: URL?

    /// CloudKit-managed metadata
    internal let modificationDate: Date?
    internal let creationDate: Date?
    internal let recordChangeTag: String?
    internal let creatorUserRecordName: String?

    internal init?(_ record: CKRecord) {
      guard record.recordType == Self.recordType else {
        return nil
      }
      self.id = record.recordID.recordName
      self.title = record[Fields.title] as? String
      self.index = (record[Fields.index] as? NSNumber)?.int64Value
      self.imageAssetURL = (record[Fields.image] as? CKAsset)?.fileURL
      self.modificationDate = record.modificationDate
      self.creationDate = record.creationDate
      self.recordChangeTag = record.recordChangeTag
      self.creatorUserRecordName = record.creatorUserRecordID?.recordName
    }

    // Identity-based equality: two Notes with the same recordID are equal
    // regardless of field state. Lets SwiftUI selection bindings track a
    // record across edits without losing focus when fields change.
    internal static func == (lhs: Note, rhs: Note) -> Bool { lhs.id == rhs.id }
    internal func hash(into hasher: inout Hasher) { hasher.combine(id) }
  }
#endif
