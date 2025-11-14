//
//  FieldValueConvenienceTests.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

import Foundation
import Testing

@testable import MistKit

@Suite("FieldValue Convenience Extensions")
/// Tests for FieldValue convenience property extractors
internal struct FieldValueConvenienceTests {
  @Test("stringValue extracts String from .string case")
  internal func stringValueExtraction() {
    let value = FieldValue.string("test")
    #expect(value.stringValue == "test")
  }

  @Test("stringValue returns nil for non-string cases")
  internal func stringValueReturnsNilForWrongType() {
    #expect(FieldValue.int64(42).stringValue == nil)
    #expect(FieldValue.double(3.14).stringValue == nil)
    #expect(FieldValue(booleanValue: true).stringValue == nil)
  }

  @Test("intValue extracts Int from .int64 case")
  internal func intValueExtraction() {
    let value = FieldValue.int64(42)
    #expect(value.intValue == 42)
  }

  @Test("intValue returns nil for non-int cases")
  internal func intValueReturnsNilForWrongType() {
    #expect(FieldValue.string("42").intValue == nil)
    #expect(FieldValue.double(42.0).intValue == nil)
  }

  @Test("doubleValue extracts Double from .double case")
  internal func doubleValueExtraction() {
    let value = FieldValue.double(3.14)
    #expect(value.doubleValue == 3.14)
  }

  @Test("doubleValue returns nil for non-double cases")
  internal func doubleValueReturnsNilForWrongType() {
    #expect(FieldValue.string("3.14").doubleValue == nil)
    #expect(FieldValue.int64(3).doubleValue == nil)
  }

  @Test("boolValue extracts Bool from .int64(0) as false")
  internal func boolValueFromInt64Zero() {
    let value = FieldValue.int64(0)
    #expect(value.boolValue == false)
  }

  @Test("boolValue extracts Bool from .int64(1) as true")
  internal func boolValueFromInt64One() {
    let value = FieldValue.int64(1)
    #expect(value.boolValue == true)
  }

  @Test("boolValue asserts for .int64 with values other than 0 or 1")
  internal func boolValueAssertsForInvalidInt64() async {
    await confirmation("Assertion handler called", expectedCount: 1) { assertionCalled in
      let value2 = FieldValue.int64(2)
      let value = value2.boolValue { condition, message in
        assertionCalled()
        #expect(condition == false)
        #expect(message == "Boolean int64 value must be 0 or 1, got 2")
      }
      #expect(value == true)  // Value is still returned (2 != 0)
    }
  }

  @Test("boolValue returns nil for non-boolean-compatible cases")
  internal func boolValueReturnsNilForWrongType() {
    #expect(FieldValue.string("true").boolValue == nil)
    #expect(FieldValue.double(1.0).boolValue == nil)
  }

  @Test("dateValue extracts Date from .date case")
  internal func dateValueExtraction() {
    let date = Date()
    let value = FieldValue.date(date)
    #expect(value.dateValue == date)
  }

  @Test("dateValue returns nil for non-date cases")
  internal func dateValueReturnsNilForWrongType() {
    #expect(FieldValue.string("2024-01-01").dateValue == nil)
    #expect(FieldValue.int64(1_704_067_200).dateValue == nil)
  }

  @Test("bytesValue extracts String from .bytes case")
  internal func bytesValueExtraction() {
    let base64 = "SGVsbG8gV29ybGQ="
    let value = FieldValue.bytes(base64)
    #expect(value.bytesValue == base64)
  }

  @Test("bytesValue returns nil for non-bytes cases")
  internal func bytesValueReturnsNilForWrongType() {
    #expect(FieldValue.string("test").bytesValue == nil)
  }

  @Test("locationValue extracts Location from .location case")
  internal func locationValueExtraction() {
    let location = FieldValue.Location(
      latitude: 37.7749,
      longitude: -122.4194,
      horizontalAccuracy: 10.0
    )
    let value = FieldValue.location(location)
    #expect(value.locationValue == location)
  }

  @Test("locationValue returns nil for non-location cases")
  internal func locationValueReturnsNilForWrongType() {
    #expect(FieldValue.string("37.7749,-122.4194").locationValue == nil)
  }

  @Test("referenceValue extracts Reference from .reference case")
  internal func referenceValueExtraction() {
    let reference = FieldValue.Reference(recordName: "test-record")
    let value = FieldValue.reference(reference)
    #expect(value.referenceValue == reference)
  }

  @Test("referenceValue returns nil for non-reference cases")
  internal func referenceValueReturnsNilForWrongType() {
    #expect(FieldValue.string("test-record").referenceValue == nil)
  }

  @Test("assetValue extracts Asset from .asset case")
  internal func assetValueExtraction() {
    let asset = FieldValue.Asset(
      fileChecksum: "abc123",
      size: 1_024,
      downloadURL: "https://example.com/file"
    )
    let value = FieldValue.asset(asset)
    #expect(value.assetValue == asset)
  }

  @Test("assetValue returns nil for non-asset cases")
  internal func assetValueReturnsNilForWrongType() {
    #expect(FieldValue.string("asset").assetValue == nil)
  }

  @Test("listValue extracts [FieldValue] from .list case")
  internal func listValueExtraction() {
    let list: [FieldValue] = [.string("one"), .int64(2), .double(3.0)]
    let value = FieldValue.list(list)
    #expect(value.listValue == list)
  }

  @Test("listValue returns nil for non-list cases")
  internal func listValueReturnsNilForWrongType() {
    #expect(FieldValue.string("[]").listValue == nil)
  }

  @Test("Convenience extractors work in field dictionary")
  internal func convenienceExtractorsInDictionary() {
    let fields: [String: FieldValue] = [
      "name": .string("Test"),
      "count": .int64(42),
      "enabled": FieldValue(booleanValue: true),
      "legacyFlag": .int64(1),
      "score": .double(98.5),
    ]

    #expect(fields["name"]?.stringValue == "Test")
    #expect(fields["count"]?.intValue == 42)
    #expect(fields["enabled"]?.boolValue == true)
    #expect(fields["legacyFlag"]?.boolValue == true)
    #expect(fields["score"]?.doubleValue == 98.5)

    // Type mismatches return nil
    #expect(fields["name"]?.intValue == nil)
    #expect(fields["count"]?.stringValue == nil)
  }
}
