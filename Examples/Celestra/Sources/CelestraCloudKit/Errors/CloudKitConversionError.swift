//
//  CloudKitConversionError.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation

/// Errors thrown during CloudKit record conversion
public enum CloudKitConversionError: LocalizedError {
  case missingRequiredField(fieldName: String, recordType: String)
  case invalidFieldType(fieldName: String, expected: String, actual: String)
  case invalidFieldValue(fieldName: String, reason: String)

  /// Localized error description
  public var errorDescription: String? {
    switch self {
    case .missingRequiredField(let field, let type):
      return "Required field '\(field)' missing in \(type) record"
    case .invalidFieldType(let field, let expected, let actual):
      return "Invalid type for '\(field)': expected \(expected), got \(actual)"
    case .invalidFieldValue(let field, let reason):
      return "Invalid value for '\(field)': \(reason)"
    }
  }
}
