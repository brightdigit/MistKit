//
//  AltTestRecord.swift
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

@testable import MistKit

/// Second CloudKit record type for collection-operation tests.
internal struct AltTestRecord: CloudKitRecord {
  internal static var cloudKitRecordType: String { "AltTestRecord" }

  internal var recordName: String
  internal var title: String

  internal static func from(recordInfo: RecordInfo) -> AltTestRecord? {
    guard let title = recordInfo.fields["title"]?.stringValue else {
      return nil
    }
    return AltTestRecord(recordName: recordInfo.recordName, title: title)
  }

  internal static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
    let title = recordInfo.fields["title"]?.stringValue ?? "Unknown"
    return "  \(recordInfo.recordName): \(title)"
  }

  internal func toCloudKitFields() -> [String: FieldValue] {
    ["title": .string(title)]
  }
}
