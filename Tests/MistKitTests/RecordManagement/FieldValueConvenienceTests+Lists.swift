//
//  FieldValueConvenienceTests+Lists.swift
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

extension FieldValueConvenienceTests {
  @Suite("List Accessors", .disabled(if: Platform.isWindowsSwift62))
  internal struct ListAccessors {
    @Test("typed *ListValue accessors unwrap homogeneous lists")
    internal func typedListValueAccessors() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        #expect(FieldValue.string(.list(["a"])).stringListValue == ["a"])
        #expect(FieldValue.string(.value("a")).stringListValue == nil)
        #expect(FieldValue.int64(.list([1, 2])).int64ListValue == [1, 2])
        #expect(FieldValue.double(.list([1.5])).doubleListValue == [1.5])
        let date = Date(timeIntervalSince1970: 0)
        #expect(FieldValue.date(.list([date])).dateListValue == [date])
        let data = Data([0x01])
        #expect(FieldValue.bytes(.list([data])).bytesListValue == [data])
        let location = Location(latitude: 1, longitude: 2, horizontalAccuracy: 3)
        #expect(FieldValue.location(.list([location])).locationListValue == [location])
        let reference = Reference(recordName: "r")
        #expect(FieldValue.reference(.list([reference])).referenceListValue == [reference])
        let asset = Asset(fileChecksum: "c", size: 1, downloadURL: "https://example.com")
        #expect(FieldValue.asset(.list([asset])).assetListValue == [asset])
        #expect(FieldValue.string(.value("x")).assetListValue == nil)
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }
  }
}
