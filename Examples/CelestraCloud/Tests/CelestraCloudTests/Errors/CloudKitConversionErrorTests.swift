//
//  CloudKitConversionErrorTests.swift
//  CelestraCloud
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

@testable import CelestraCloudKit

@Suite("CloudKitConversionError Tests")
internal struct CloudKitConversionErrorTests {
  @Test("Missing required field error description")
  internal func testMissingRequiredFieldDescription() {
    let error = CloudKitConversionError.missingRequiredField(
      fieldName: "feedURL",
      recordType: "Feed"
    )

    let description = error.errorDescription
    #expect(description?.contains("feedURL") == true)
    #expect(description?.contains("Feed") == true)
    #expect(description?.contains("Required field") == true)
    #expect(description?.contains("missing") == true)
  }

  @Test("Invalid field type error description")
  internal func testInvalidFieldTypeDescription() {
    let error = CloudKitConversionError.invalidFieldType(
      fieldName: "subscriberCount",
      expected: "Int64",
      actual: "String"
    )

    let description = error.errorDescription
    #expect(description?.contains("subscriberCount") == true)
    #expect(description?.contains("Int64") == true)
    #expect(description?.contains("String") == true)
    #expect(description?.contains("Invalid type") == true)
  }

  @Test("Invalid field value error description")
  internal func testInvalidFieldValueDescription() {
    let error = CloudKitConversionError.invalidFieldValue(
      fieldName: "feedURL",
      reason: "Not a valid URL"
    )

    let description = error.errorDescription
    #expect(description?.contains("feedURL") == true)
    #expect(description?.contains("Not a valid URL") == true)
    #expect(description?.contains("Invalid value") == true)
  }

  @Test("Missing required field with empty string")
  internal func testMissingRequiredFieldEmptyString() {
    let error = CloudKitConversionError.missingRequiredField(
      fieldName: "",
      recordType: "Article"
    )

    let description = error.errorDescription
    #expect(description != nil)
    #expect(description?.contains("Article") == true)
  }

  @Test("Error is LocalizedError")
  internal func testLocalizedErrorConformance() {
    let error: any LocalizedError = CloudKitConversionError.missingRequiredField(
      fieldName: "title",
      recordType: "Feed"
    )

    #expect(error.errorDescription != nil)
  }

  @Test("Different field names produce different descriptions")
  internal func testDifferentFieldNames() {
    let error1 = CloudKitConversionError.missingRequiredField(
      fieldName: "title",
      recordType: "Feed"
    )
    let error2 = CloudKitConversionError.missingRequiredField(
      fieldName: "guid",
      recordType: "Feed"
    )

    #expect(error1.errorDescription != error2.errorDescription)
    #expect(error1.errorDescription?.contains("title") == true)
    #expect(error2.errorDescription?.contains("guid") == true)
  }

  @Test("Different record types produce different descriptions")
  internal func testDifferentRecordTypes() {
    let error1 = CloudKitConversionError.missingRequiredField(
      fieldName: "title",
      recordType: "Feed"
    )
    let error2 = CloudKitConversionError.missingRequiredField(
      fieldName: "title",
      recordType: "Article"
    )

    #expect(error1.errorDescription != error2.errorDescription)
    #expect(error1.errorDescription?.contains("Feed") == true)
    #expect(error2.errorDescription?.contains("Article") == true)
  }
}
