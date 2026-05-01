//
//  CloudKitModels.swift
//  MistDemoApp
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

import CloudKit
import Foundation

/// Display-friendly snapshot of a CKRecordZone for the SwiftUI list.
struct ZoneRow: Identifiable, Hashable {
    let id: String
    let zoneName: String
    let ownerName: String

    init(_ zone: CKRecordZone) {
        self.id = "\(zone.zoneID.zoneName)|\(zone.zoneID.ownerName)"
        self.zoneName = zone.zoneID.zoneName
        self.ownerName = zone.zoneID.ownerName
    }
}

/// Display-friendly snapshot of a CKRecord for the SwiftUI list and detail views.
struct RecordRow: Identifiable, Hashable {
    let id: String
    let recordType: String
    let recordName: String
    let modificationDate: Date?
    let fields: [(key: String, valueDescription: String)]

    init(_ record: CKRecord) {
        self.id = record.recordID.recordName
        self.recordType = record.recordType
        self.recordName = record.recordID.recordName
        self.modificationDate = record.modificationDate
        self.fields = record.allKeys()
            .sorted()
            .map { key in
                let value = record[key]
                return (key: key, valueDescription: Self.describe(value))
            }
    }

    private static func describe(_ value: CKRecordValue?) -> String {
        guard let value else { return "nil" }
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        case let date as Date:
            return ISO8601DateFormatter().string(from: date)
        case let asset as CKAsset:
            return asset.fileURL?.lastPathComponent ?? "<asset>"
        case let reference as CKRecord.Reference:
            return "→ \(reference.recordID.recordName)"
        default:
            return String(describing: value)
        }
    }

    static func == (lhs: RecordRow, rhs: RecordRow) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
