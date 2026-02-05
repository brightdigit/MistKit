//
//  DataSourceMetadata+CloudKit.swift
//  BushelCloud
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

public import BushelFoundation
public import BushelUtilities
public import Foundation
public import MistKit

// MARK: - CloudKitRecord Conformance

extension DataSourceMetadata: CloudKitRecord {
  public static var cloudKitRecordType: String { "DataSourceMetadata" }

  public static func from(recordInfo: RecordInfo) -> Self? {
    guard let sourceName = recordInfo.fields["sourceName"]?.stringValue,
      let recordTypeName = recordInfo.fields["recordTypeName"]?.stringValue,
      let lastFetchedAt = recordInfo.fields["lastFetchedAt"]?.dateValue
    else {
      return nil
    }

    return DataSourceMetadata(
      sourceName: sourceName,
      recordTypeName: recordTypeName,
      lastFetchedAt: lastFetchedAt,
      sourceUpdatedAt: recordInfo.fields["sourceUpdatedAt"]?.dateValue,
      recordCount: recordInfo.fields["recordCount"]?.intValue ?? 0,
      fetchDurationSeconds: recordInfo.fields["fetchDurationSeconds"]?.doubleValue ?? 0,
      lastError: recordInfo.fields["lastError"]?.stringValue
    )
  }

  public static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
    let sourceName = recordInfo.fields["sourceName"]?.stringValue ?? "Unknown"
    let recordTypeName = recordInfo.fields["recordTypeName"]?.stringValue ?? "Unknown"
    let lastFetchedAt = recordInfo.fields["lastFetchedAt"]?.dateValue
    let recordCount = recordInfo.fields["recordCount"]?.intValue ?? 0

    let dateStr = lastFetchedAt.map { Formatters.dateTimeFormat.format($0) } ?? "Unknown"

    var output = "\n  \(sourceName) → \(recordTypeName)\n"
    output += "    Last fetched: \(dateStr) | Records: \(recordCount)"
    return output
  }

  public func toCloudKitFields() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "sourceName": .string(sourceName),
      "recordTypeName": .string(recordTypeName),
      "lastFetchedAt": .date(lastFetchedAt),
      "recordCount": .int64(recordCount),
      "fetchDurationSeconds": .double(fetchDurationSeconds),
    ]

    // Optional fields
    if let sourceUpdatedAt {
      fields["sourceUpdatedAt"] = .date(sourceUpdatedAt)
    }

    if let lastError {
      fields["lastError"] = .string(lastError)
    }

    return fields
  }
}
