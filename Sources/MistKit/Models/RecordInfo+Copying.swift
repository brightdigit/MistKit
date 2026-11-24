//
//  RecordInfo+Copying.swift
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
  /// The record's zone, or ``ZoneID/defaultZone`` when the response left it
  /// out (CloudKit reads a missing zone as the default zone).
  public var zoneOrDefault: ZoneID { zoneID ?? .defaultZone }

  /// A copy with the given properties replaced; `nil` keeps the current one.
  ///
  /// `RecordInfo`'s properties are constants, so code that edits a record
  /// builds changed copies with this.
  ///
  /// - Parameters:
  ///   - recordName: The new record name.
  ///   - zoneID: The new zone.
  ///   - recordType: The new record type.
  ///   - recordChangeTag: The new change tag.
  ///   - fields: The new fields, replacing all of them.
  /// - Returns: The copy.
  public func replacing(
    recordName: String? = nil,
    zoneID: ZoneID? = nil,
    recordType: String? = nil,
    recordChangeTag: String? = nil,
    fields: [String: FieldValue]? = nil
  ) -> RecordInfo {
    RecordInfo(
      recordName: recordName ?? self.recordName,
      zoneID: zoneID ?? self.zoneID,
      recordType: recordType ?? self.recordType,
      recordChangeTag: recordChangeTag ?? self.recordChangeTag,
      fields: fields ?? self.fields,
      encryptedFields: encryptedFields,
      created: created,
      modified: modified,
      deleted: deleted
    )
  }
}
