//
//  XcodeVersionRecord+CloudKit.swift
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

extension XcodeVersionRecord: @retroactive CloudKitRecord {
  public static var cloudKitRecordType: String { "XcodeVersion" }

  public static func from(recordInfo: RecordInfo) -> Self? {
    guard let version = recordInfo.fields["version"]?.stringValue,
      let buildNumber = recordInfo.fields["buildNumber"]?.stringValue,
      let releaseDate = recordInfo.fields["releaseDate"]?.dateValue
    else {
      return nil
    }

    return XcodeVersionRecord(
      version: version,
      buildNumber: buildNumber,
      releaseDate: releaseDate,
      downloadURL: recordInfo.fields["downloadURL"]?.urlValue,
      fileSize: recordInfo.fields["fileSize"]?.intValue,
      isPrerelease: recordInfo.fields["isPrerelease"]?.boolValue ?? false,
      minimumMacOS: recordInfo.fields["minimumMacOS"]?.referenceValue?.recordName,
      includedSwiftVersion: recordInfo.fields["includedSwiftVersion"]?.referenceValue?.recordName,
      sdkVersions: recordInfo.fields["sdkVersions"]?.stringValue,
      notes: recordInfo.fields["notes"]?.stringValue
    )
  }

  public static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
    let version = recordInfo.fields["version"]?.stringValue ?? "Unknown"
    let build = recordInfo.fields["buildNumber"]?.stringValue ?? "Unknown"
    let releaseDate = recordInfo.fields["releaseDate"]?.dateValue
    let size = recordInfo.fields["fileSize"]?.intValue ?? 0

    let dateStr = releaseDate.map { Formatters.dateFormat.format($0) } ?? "Unknown"
    let sizeStr = Formatters.fileSizeFormat.format(Int64(size))

    var output = "\n  \(version) (Build \(build))\n"
    output += "    Released: \(dateStr) | Size: \(sizeStr)"
    return output
  }

  public func toCloudKitFields() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "version": .string(version),
      "buildNumber": .string(buildNumber),
      "releaseDate": .date(releaseDate),
      "isPrerelease": FieldValue(booleanValue: isPrerelease),
    ]

    // Optional fields
    if let downloadURL {
      fields["downloadURL"] = FieldValue(url: downloadURL)
    }

    if let fileSize {
      fields["fileSize"] = .int64(fileSize)
    }

    if let minimumMacOS {
      fields["minimumMacOS"] = .reference(
        FieldValue.Reference(
          recordName: minimumMacOS,
          action: nil
        )
      )
    }

    if let includedSwiftVersion {
      fields["includedSwiftVersion"] = .reference(
        FieldValue.Reference(
          recordName: includedSwiftVersion,
          action: nil
        )
      )
    }

    if let sdkVersions {
      fields["sdkVersions"] = .string(sdkVersions)
    }

    if let notes {
      fields["notes"] = .string(notes)
    }

    return fields
  }
}
