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

public import Foundation

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
public struct Note: Identifiable, Hashable {
  public init(id: String, title: String? = nil, index: Int64? = nil, imageAssetURL: URL? = nil, modificationDate: Date? = nil, creationDate: Date? = nil, recordChangeTag: String? = nil, creatorUserRecordName: String? = nil) {
    self.id = id
    self.title = title
    self.index = index
    self.imageAssetURL = imageAssetURL
    self.modificationDate = modificationDate
    self.creationDate = creationDate
    self.recordChangeTag = recordChangeTag
    self.creatorUserRecordName = creatorUserRecordName
  }
  
    /// Known field name constants for `Note` records.
    public enum Fields {
      public static let title = "title"
      public static let index = "index"
      public static let image = "image"
    }

    /// CloudKit record type identifier.
    public static let recordType = "Note"

    public let id: String
    public let title: String?
    public let index: Int64?
    public let imageAssetURL: URL?

    /// CloudKit-managed metadata
    public let modificationDate: Date?
    public let creationDate: Date?
    public let recordChangeTag: String?
    public let creatorUserRecordName: String?

//    internal init?(_ record: CKRecord) {
//      guard record.recordType == Self.recordType else {
//        return nil
//      }
//      self.id = record.recordID.recordName
//      self.title = record[Fields.title] as? String
//      self.index = (record[Fields.index] as? NSNumber)?.int64Value
//      self.imageAssetURL = (record[Fields.image] as? CKAsset)?.fileURL
//      self.modificationDate = record.modificationDate
//      self.creationDate = record.creationDate
//      self.recordChangeTag = record.recordChangeTag
//      self.creatorUserRecordName = record.creatorUserRecordID?.recordName
//    }

    // Identity-based equality: two Notes with the same recordID are equal
    // regardless of field state. Lets SwiftUI selection bindings track a
    // record across edits without losing focus when fields change.
    public static func == (lhs: Note, rhs: Note) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
  }
