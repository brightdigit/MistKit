//
//  SwiftVersionRecord+CloudKit.swift
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

extension SwiftVersionRecord: @retroactive CloudKitRecord {
  public static var cloudKitRecordType: String { "SwiftVersion" }

  public static func from(recordInfo: RecordInfo) -> Self? {
    guard let version = recordInfo.fields["version"]?.stringValue,
      let releaseDate = recordInfo.fields["releaseDate"]?.dateValue
    else {
      return nil
    }

    return SwiftVersionRecord(
      version: version,
      releaseDate: releaseDate,
      downloadURL: recordInfo.fields["downloadURL"]?.urlValue,
      isPrerelease: recordInfo.fields["isPrerelease"]?.boolValue ?? false,
      notes: recordInfo.fields["notes"]?.stringValue
    )
  }

  public static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
    let version = recordInfo.fields["version"]?.stringValue ?? "Unknown"
    let releaseDate = recordInfo.fields["releaseDate"]?.dateValue

    let dateStr = releaseDate.map { Formatters.dateFormat.format($0) } ?? "Unknown"

    var output = "\n  Swift \(version)\n"
    output += "    Released: \(dateStr)"
    return output
  }

  public func toCloudKitFields() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "version": .string(version),
      "releaseDate": .date(releaseDate),
      "isPrerelease": FieldValue(booleanValue: isPrerelease),
    ]

    // Optional fields
    if let downloadURL {
      fields["downloadURL"] = FieldValue(url: downloadURL)
    }

    if let notes {
      fields["notes"] = .string(notes)
    }

    return fields
  }
}
