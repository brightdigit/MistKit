//
//  QueryOperand.swift
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

/// A condition's value on its way into a ``QueryFilter``.
internal struct QueryOperand {
  /// The value, with record names as references on `___recordID`.
  internal let value: FieldValue

  /// The value as a single comparable scalar; `nil` for assets and lists.
  internal var scalar: FieldValue? {
    guard value.fieldType != .asset, !value.fieldType.isList else {
      return nil
    }
    return value
  }

  /// The elements of a list value, for `IN` and `NOT_IN`; `nil` for scalars
  /// and asset lists.
  internal var listElements: [FieldValue]? {
    guard value.fieldType != .list(.asset) else {
      return nil
    }
    return value.listElements
  }

  /// The center of a `NEAR` filter: the location's coordinates and accuracy.
  internal var nearCenter: Location? {
    guard case .location(.value(let location)) = value else {
      return nil
    }
    return Location(
      latitude: location.latitude,
      longitude: location.longitude,
      horizontalAccuracy: location.horizontalAccuracy
    )
  }

  internal init(_ value: FieldValue, isRecordID: Bool) {
    switch value {
    case .string(.value(let name)) where isRecordID:
      self.value = .reference(.value(Reference(recordName: name)))
    case .string(.list(let names)) where isRecordID:
      self.value = .reference(.list(names.map { Reference(recordName: $0) }))
    case .reference(.value(let reference)):
      self.value = .reference(.value(Self.comparable(reference)))
    case .reference(.list(let references)):
      self.value = .reference(.list(references.map(Self.comparable)))
    default:
      self.value = value
    }
  }

  /// A reference without its action, which filters don't take.
  private static func comparable(_ reference: Reference) -> Reference {
    Reference(recordName: reference.recordName, zoneID: reference.zoneID)
  }
}
