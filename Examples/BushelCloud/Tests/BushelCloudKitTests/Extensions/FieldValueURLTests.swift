//
//  FieldValueURLTests.swift
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

internal import Foundation
internal import MistKit
internal import Testing

@testable import BushelCloudKit

internal struct FieldValueURLTests {
  // MARK: - URL → FieldValue Conversion Tests

  @Test("Create FieldValue from URL")
  internal func testCreateFieldValueFromURL() throws {
    let url = URL(string: "https://example.com/file.dmg")!
    let fieldValue = FieldValue(url: url)

    if case .string(let value) = fieldValue {
      #expect(value == "https://example.com/file.dmg")
    } else {
      Issue.record("Expected .string FieldValue")
    }
  }

  @Test("Create FieldValue from URL with path")
  internal func testCreateFieldValueFromURLWithPath() throws {
    let url = URL(string: "https://example.com/path/to/file.ipsw")!
    let fieldValue = FieldValue(url: url)

    if case .string(let value) = fieldValue {
      #expect(value == "https://example.com/path/to/file.ipsw")
    } else {
      Issue.record("Expected .string FieldValue")
    }
  }

  @Test("Create FieldValue from URL with query parameters")
  internal func testCreateFieldValueFromURLWithQueryParams() throws {
    let url = URL(string: "https://example.com/file.dmg?version=1.0&platform=mac")!
    let fieldValue = FieldValue(url: url)

    if case .string(let value) = fieldValue {
      #expect(value == "https://example.com/file.dmg?version=1.0&platform=mac")
    } else {
      Issue.record("Expected .string FieldValue")
    }
  }

  @Test("Create FieldValue from file URL")
  internal func testCreateFieldValueFromFileURL() throws {
    let url = URL(fileURLWithPath: "/Users/test/file.dmg")
    let fieldValue = FieldValue(url: url)

    if case .string(let value) = fieldValue {
      #expect(value == "file:///Users/test/file.dmg")
    } else {
      Issue.record("Expected .string FieldValue")
    }
  }

  // MARK: - FieldValue → URL Extraction Tests

  @Test("Extract URL from string FieldValue")
  internal func testExtractURLFromStringFieldValue() throws {
    let fieldValue: FieldValue = .string("https://example.com/file.dmg")
    let url = fieldValue.urlValue

    #expect(url != nil)
    #expect(url?.absoluteString == "https://example.com/file.dmg")
  }

  @Test("Extract URL from string FieldValue with path")
  internal func testExtractURLFromStringFieldValueWithPath() throws {
    let fieldValue: FieldValue = .string("https://downloads.apple.com/restore/macOS/23C71.ipsw")
    let url = fieldValue.urlValue

    #expect(url != nil)
    #expect(url?.absoluteString == "https://downloads.apple.com/restore/macOS/23C71.ipsw")
  }

  @Test("Extract nil from invalid URL string")
  internal func testExtractNilFromInvalidURLString() throws {
    // URL(string:) is lenient - even "not a valid url" parses successfully
    // as a relative URL with no scheme. Test actual parsing behavior:
    let fieldValue: FieldValue = .string("not a valid url")
    let url = fieldValue.urlValue

    // This actually succeeds - URL is lenient and creates a relative URL
    #expect(url != nil)
    #expect(url?.scheme == nil)  // No scheme for this "URL"

    // Test a URL with invalid characters
    let malformedFieldValue: FieldValue = .string("ht!tp://invalid")
    let malformedURL = malformedFieldValue.urlValue

    // URLs with certain invalid characters DO fail to parse
    // This demonstrates that URL(string:) has some limits
    #expect(malformedURL == nil)
  }

  @Test("Extract nil from empty string")
  internal func testExtractNilFromEmptyString() throws {
    let fieldValue: FieldValue = .string("")
    let url = fieldValue.urlValue

    // Note: URL(string: "") returns nil (empty string is not a valid URL)
    #expect(url == nil)
  }

  @Test("Extract nil from non-string FieldValue")
  internal func testExtractNilFromNonStringFieldValue() throws {
    let intFieldValue: FieldValue = .int64(42)
    #expect(intFieldValue.urlValue == nil)

    let doubleFieldValue: FieldValue = .double(3.14)
    #expect(doubleFieldValue.urlValue == nil)

    let dateFieldValue: FieldValue = .date(Date())
    #expect(dateFieldValue.urlValue == nil)
  }

  // MARK: - Round-Trip Tests

  @Test("Round-trip URL through FieldValue")
  internal func testRoundTripURLThroughFieldValue() throws {
    let originalURL = URL(string: "https://example.com/file.dmg")!
    let fieldValue = FieldValue(url: originalURL)
    let extractedURL = fieldValue.urlValue

    #expect(extractedURL != nil)
    #expect(extractedURL?.absoluteString == originalURL.absoluteString)
  }

  @Test("Round-trip complex URL through FieldValue")
  internal func testRoundTripComplexURLThroughFieldValue() throws {
    let originalURL = URL(
      string:
        "https://updates.cdn-apple.com/2024/restore/macOS/"
        + "052-49876-20241103-B6C6AA6A-D39E-4F6C-B43C-15C3B8A4CB1A/UniversalMac_15.1.1_24B91_Restore.ipsw"
    )!
    let fieldValue = FieldValue(url: originalURL)
    let extractedURL = fieldValue.urlValue

    #expect(extractedURL != nil)
    #expect(extractedURL?.absoluteString == originalURL.absoluteString)
  }

  @Test("Round-trip file URL through FieldValue")
  internal func testRoundTripFileURLThroughFieldValue() throws {
    let originalURL = URL(fileURLWithPath: "/System/Library/Frameworks/Virtualization.framework")
    let fieldValue = FieldValue(url: originalURL)
    let extractedURL = fieldValue.urlValue

    #expect(extractedURL != nil)
    #expect(extractedURL?.absoluteString == originalURL.absoluteString)
    #expect(extractedURL?.isFileURL == true)
  }

  // MARK: - Type Safety Tests

  @Test("FieldValue from URL is string type")
  internal func testFieldValueFromURLIsStringType() throws {
    let url = URL(string: "https://example.com")!
    let fieldValue = FieldValue(url: url)

    switch fieldValue {
    case .string:
      #expect(true)
    default:
      Issue.record("Expected .string FieldValue, got \(fieldValue)")
    }
  }

  @Test("URL extraction preserves scheme")
  internal func testURLExtractionPreservesScheme() throws {
    let httpsFieldValue = FieldValue(url: URL(string: "https://example.com")!)
    let httpFieldValue = FieldValue(url: URL(string: "http://example.com")!)
    let fileFieldValue = FieldValue(url: URL(fileURLWithPath: "/tmp/file"))

    #expect(httpsFieldValue.urlValue?.scheme == "https")
    #expect(httpFieldValue.urlValue?.scheme == "http")
    #expect(fileFieldValue.urlValue?.scheme == "file")
  }

  // MARK: - CloudKit Integration Tests

  @Test("FieldValue URL matches CloudKit STRING field format")
  internal func testFieldValueURLMatchesCloudKitStringFormat() throws {
    // CloudKit stores URLs as STRING fields
    // This test verifies the format is compatible
    let url = URL(string: "https://downloads.apple.com/restore/macOS/23C71.ipsw")!
    let fieldValue = FieldValue(url: url)

    // When sent to CloudKit, this becomes a STRING field with the absolute URL
    if case .string(let stringValue) = fieldValue {
      // Verify it's a valid absolute URL string
      #expect(stringValue.hasPrefix("https://"))
      #expect(URL(string: stringValue) != nil)
    } else {
      Issue.record("FieldValue should be .string type for CloudKit compatibility")
    }
  }
}
