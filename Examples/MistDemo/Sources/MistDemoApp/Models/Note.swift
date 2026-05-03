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
  ///         "title"     STRING    QUERYABLE SORTABLE SEARCHABLE,
  ///         "index"     INT64     QUERYABLE SORTABLE,
  ///         "image"     ASSET,
  ///         "createdAt" TIMESTAMP QUERYABLE SORTABLE,
  ///         "modified"  INT64     QUERYABLE
  ///     );
  struct Note: Identifiable, Hashable {
    static let recordType = "Note"

    enum Fields {
      static let title = "title"
      static let index = "index"
      static let image = "image"
      static let createdAt = "createdAt"
      static let modified = "modified"
    }

    let id: String
    let title: String?
    let index: Int64?
    let imageAssetURL: URL?
    let createdAt: Date?
    let modified: Int64?

    /// CloudKit-managed metadata
    let modificationDate: Date?
    let creationDate: Date?
    let recordChangeTag: String?

    init?(_ record: CKRecord) {
      guard record.recordType == Self.recordType else { return nil }
      self.id = record.recordID.recordName
      self.title = record[Fields.title] as? String
      self.index = (record[Fields.index] as? NSNumber)?.int64Value
      self.imageAssetURL = (record[Fields.image] as? CKAsset)?.fileURL
      self.createdAt = record[Fields.createdAt] as? Date
      self.modified = (record[Fields.modified] as? NSNumber)?.int64Value
      self.modificationDate = record.modificationDate
      self.creationDate = record.creationDate
      self.recordChangeTag = record.recordChangeTag
    }

    // Identity-based equality: two Notes with the same recordID are equal
    // regardless of field state. Lets SwiftUI selection bindings track a
    // record across edits without losing focus when fields change.
    static func == (lhs: Note, rhs: Note) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
  }
#endif
