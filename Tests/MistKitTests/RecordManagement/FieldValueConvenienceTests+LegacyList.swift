//
//  FieldValueConvenienceTests+LegacyList.swift
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
internal import Testing

@testable import MistKit

/// Protocol shim so deprecated ``FieldValue/listValue`` can be exercised without
/// `DeprecatedDeclaration` warnings (same pattern as FetchZoneChangesAPI).
internal protocol FieldValueLegacyListReading {
  var listValue: [FieldValue]? { get }
}

extension FieldValue: FieldValueLegacyListReading {}

extension FieldValueConvenienceTests {
  @Suite("Legacy listValue", .disabled(if: Platform.isWindowsSwift62))
  internal struct LegacyList {
    @Test("listValue flattens every homogeneous list kind to [FieldValue] of .value")
    internal func listValueExtraction() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        let string: any FieldValueLegacyListReading = FieldValue.string(.list(["one", "two"]))
        #expect(string.listValue == [.string(.value("one")), .string(.value("two"))])

        let ints: any FieldValueLegacyListReading = FieldValue.int64(.list([1, 2]))
        #expect(ints.listValue == [.int64(.value(1)), .int64(.value(2))])

        let doubles: any FieldValueLegacyListReading = FieldValue.double(.list([1.5]))
        #expect(doubles.listValue == [.double(.value(1.5))])

        let date = Date(timeIntervalSince1970: 0)
        let dates: any FieldValueLegacyListReading = FieldValue.date(.list([date]))
        #expect(dates.listValue == [.date(.value(date))])

        let data = Data([0x01])
        let bytes: any FieldValueLegacyListReading = FieldValue.bytes(.list([data]))
        #expect(bytes.listValue == [.bytes(.value(data))])

        let location = Location(latitude: 1, longitude: 2)
        let locations: any FieldValueLegacyListReading = FieldValue.location(.list([location]))
        #expect(locations.listValue == [.location(.value(location))])

        let reference = Reference(recordName: "r")
        let references: any FieldValueLegacyListReading = FieldValue.reference(.list([reference]))
        #expect(references.listValue == [.reference(.value(reference))])

        let asset = Asset(fileChecksum: "c", size: 1, downloadURL: "https://example.com")
        let assets: any FieldValueLegacyListReading = FieldValue.asset(.list([asset]))
        #expect(assets.listValue == [.asset(.value(asset))])
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }

    @Test("listValue returns nil for non-list cases")
    internal func listValueReturnsNilForWrongType() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        let value: any FieldValueLegacyListReading = FieldValue.string(.value("[]"))
        #expect(value.listValue == nil)
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }
  }
}
