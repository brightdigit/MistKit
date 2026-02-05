//
//  FieldValueAssertions.swift
//  BushelCloud
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

public import Foundation
public import MistKit
import Testing

/// Custom assertions for FieldValue comparisons
extension FieldValue {
  /// Asserts that this FieldValue is a string with the expected value
  public func assertStringEquals(_ expected: String) {
    guard case .string(let actual) = self else {
      Issue.record("Expected .string, got \(self)")
      return
    }
    #expect(actual == expected)
  }

  /// Asserts that this FieldValue is an int64 with the expected value
  public func assertInt64Equals(_ expected: Int) {
    guard case .int64(let actual) = self else {
      Issue.record("Expected .int64, got \(self)")
      return
    }
    #expect(actual == expected)
  }

  /// Asserts that this FieldValue is a double with the expected value
  public func assertDoubleEquals(_ expected: Double) {
    guard case .double(let actual) = self else {
      Issue.record("Expected .double, got \(self)")
      return
    }
    #expect(actual == expected)
  }

  /// Asserts that this FieldValue is a boolean stored as INT64 (0 or 1)
  public func assertBoolEquals(_ expected: Bool) {
    // Boolean is stored as INT64 (0 or 1) in CloudKit
    guard case .int64(let actual) = self else {
      Issue.record("Expected .int64 (boolean), got \(self)")
      return
    }
    let actualBool = actual == 1
    #expect(actualBool == expected)
  }

  /// Asserts that this FieldValue is a reference with the expected record name
  public func assertReferenceEquals(_ expectedRecordName: String) {
    guard case .reference(let ref) = self else {
      Issue.record("Expected .reference, got \(self)")
      return
    }
    #expect(ref.recordName == expectedRecordName)
  }

  /// Asserts that this FieldValue is a date (does not validate the exact value)
  public func assertIsDate() {
    guard case .date = self else {
      Issue.record("Expected .date, got \(self)")
      return
    }
  }

  /// Asserts that this FieldValue is a date with the expected value
  public func assertDateEquals(_ expected: Date) {
    guard case .date(let actual) = self else {
      Issue.record("Expected .date, got \(self)")
      return
    }
    // Compare timestamps with 1-second tolerance to account for precision differences
    #expect(abs(actual.timeIntervalSince(expected)) < 1.0)
  }
}
