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
  /// Wraps a `CKRecord` rather than copying fields out of it — the record is
  /// the source of truth, so an update can mutate it in place and `save` it
  /// without re-fetching to refresh the change tag.
  internal struct Note: Identifiable, Hashable {
    /// Known field name constants for `Note` records.
    internal enum Fields {
      internal static let title = "title"
      internal static let index = "index"
      internal static let image = "image"
    }

    /// CloudKit record type identifier.
    internal static let recordType = "Note"

    internal let record: CKRecord

    internal var id: CKRecord.ID { record.recordID }
    internal var recordName: String { record.recordID.recordName }
    internal var title: String? { record[Fields.title] as? String }
    internal var index: Int64? { (record[Fields.index] as? NSNumber)?.int64Value }
    internal var imageAssetURL: URL? { (record[Fields.image] as? CKAsset)?.fileURL }
    internal var creationDate: Date? { record.creationDate }
    internal var modificationDate: Date? { record.modificationDate }
    internal var recordChangeTag: String? { record.recordChangeTag }

    internal init?(_ record: CKRecord) {
      guard record.recordType == Self.recordType else {
        return nil
      }
      self.record = record
    }

    // Identity-based equality so SwiftUI selection / NavigationLink paths
    // remain stable across edits. RecordDetailView replaces its `@State` Note
    // with a fresh wrapper after save, which is what drives the re-render —
    // not Equatable comparison.
    internal static func == (lhs: Note, rhs: Note) -> Bool {
      lhs.record.recordID == rhs.record.recordID
    }
    internal func hash(into hasher: inout Hasher) {
      hasher.combine(record.recordID)
    }
  }
#endif
