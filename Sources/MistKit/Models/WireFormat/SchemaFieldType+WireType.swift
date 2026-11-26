//
//  SchemaFieldType+WireType.swift
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

internal import MistKitOpenAPI

extension SchemaFieldType {
  /// The `type` a CloudKit field dictionary carries for this schema type;
  /// `nil` for an unpreferred `NUMBER`, which can be either.
  internal var responseType: Components.Schemas.FieldValueResponse._typePayload? {
    let scalar: String
    switch primitive {
    case .asset: scalar = "ASSET"
    case .bytes: scalar = "BYTES"
    case .double, .number(preferredAs: .double): scalar = "DOUBLE"
    case .int64, .number(preferredAs: .int64): scalar = "INT64"
    case .location: scalar = "LOCATION"
    case .number(preferredAs: nil): return nil
    case .reference: scalar = "REFERENCE"
    case .string: scalar = "STRING"
    case .timestamp: scalar = "TIMESTAMP"
    }
    return .init(rawValue: isList ? scalar + "_LIST" : scalar)
  }
}
