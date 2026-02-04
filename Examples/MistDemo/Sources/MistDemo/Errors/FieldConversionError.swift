//
//  FieldConversionError.swift
//  MistDemo
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

public import Foundation
public import MistKit

/// Errors that can occur during field conversion
public enum FieldConversionError: Error, LocalizedError {
  case conversionFailed(fieldName: String, fieldType: FieldType, value: String, reason: String)
  case invalidFieldValue(fieldType: FieldType, value: String)

  public var errorDescription: String? {
    switch self {
    case .conversionFailed(let fieldName, let fieldType, let value, let reason):
      return "Failed to convert field '\(fieldName)' of type '\(fieldType.rawValue)' with value '\(value)': \(reason)"
    case .invalidFieldValue(let fieldType, let value):
      return "Unable to convert value '\(value)' to FieldValue for type '\(fieldType.rawValue)'"
    }
  }
}
