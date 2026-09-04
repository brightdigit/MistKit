//
//  FieldValue+FieldType.swift
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

internal import Foundation
public import MistKit

extension FieldValue {
  /// Initialize FieldValue from a parsed value and field type.
  ///
  /// This convenience initializer simplifies converting MistDemo's parsed
  /// field values into MistKit's FieldValue enum cases.
  ///
  /// - Parameters:
  ///   - value: The parsed value (from FieldType.convertValue)
  ///   - fieldType: The MistDemo FieldType for this value
  public init?(value: Any, fieldType: FieldType) {
    guard let converted = FieldValue.convert(value: value, fieldType: fieldType) else {
      return nil
    }
    self = converted
  }

  // swiftlint:disable:next cyclomatic_complexity
  private static func convert(value: Any, fieldType: FieldType) -> FieldValue? {
    switch fieldType {
    case .string:
      guard let stringValue = value as? String else {
        return nil
      }
      return .string(stringValue)

    case .int64:
      return convertInt64(value: value)

    case .double:
      guard let doubleValue = value as? Double else {
        return nil
      }
      return .double(doubleValue)

    case .timestamp:
      guard let dateValue = value as? Date else {
        return nil
      }
      return .date(dateValue)

    case .bytes:
      guard let stringValue = value as? String,
        let data = Data(base64Encoded: stringValue)
      else {
        return nil
      }
      return .bytes(data)

    case .asset:
      return convertAsset(value: value)

    case .location, .reference:
      // These complex types require specialized handling
      // For now, return nil to indicate they're not supported via simple conversion
      return nil
    }
  }

  private static func convertInt64(value: Any) -> FieldValue? {
    if let intValue = value as? Int64 {
      return .int64(Int(intValue))
    } else if let intValue = value as? Int {
      return .int64(intValue)
    }
    return nil
  }

  private static func convertAsset(value: Any) -> FieldValue? {
    // Value should be the URL from upload token
    guard let urlString = value as? String else {
      return nil
    }
    let asset = Asset(
      fileChecksum: nil,
      size: nil,
      referenceChecksum: nil,
      wrappingKey: nil,
      receipt: nil,
      downloadURL: urlString
    )
    return .asset(asset)
  }
}
