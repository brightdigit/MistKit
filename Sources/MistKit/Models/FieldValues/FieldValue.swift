//
//  FieldValue.swift
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

public import Foundation

/// Represents a CloudKit field value as defined in the CloudKit Web Services API.
///
/// Each kind carries ``Arity`` so a field is either a single value or a homogeneous
/// list of that kind. Heterogeneous and nested lists are unrepresentable — matching
/// CloudKit's `LIST<primitive-type>` schema grammar (issue #481).
public enum FieldValue: Codable, Equatable, Sendable {
  case string(Arity<String>)
  case int64(Arity<Int>)
  case double(Arity<Double>)
  case bytes(Arity<Data>)  // Binary data; base64-encoded on the wire
  case date(Arity<Date>)  // Date/time value
  case location(Arity<Location>)
  case reference(Arity<Reference>)
  case asset(Arity<Asset>)
}

extension FieldValue {
  /// Whether a field holds one value or a homogeneous list of that kind.
  ///
  /// Empty lists use `.list([])` on the appropriate kind (e.g. `.string(.list([]))`);
  /// there is no separate empty case — the element type is part of the domain value
  /// even when the array is empty.
  public enum Arity<T: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    case value(T)
    case list([T])
  }
}
