//
//  WireFieldValue.swift
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
internal import MistKitOpenAPI

/// One record field in CloudKit Web Services JSON: `{"value": …, "type": …}`.
///
/// Encodes exactly what MistKit sends in a `records/modify` request (TIMESTAMP
/// as whole milliseconds, BYTES as base64, lists tagged `*_LIST`, a reference's
/// non-default `zoneID`), and decodes what CloudKit returns, recovering the
/// ambiguous scalars from `type` the same way query and lookup responses do.
///
/// A `nil` ``value`` is a cleared field, `{"value": null}`.
///
/// ```swift
/// let data = try JSONEncoder().encode(
///   WireFieldValue(.date(.value(Date())), typeTagging: .always)
/// )
/// // {"value":1790000000500,"type":"TIMESTAMP"}
/// ```
public struct WireFieldValue: Codable, Equatable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case value
  }

  /// The value, or `nil` for a cleared field.
  public var value: FieldValue?
  /// When the encoded dictionary carries `type`. Decoding sets ``FieldTypeTagging/always``
  /// when the dictionary had a `type`.
  public var typeTagging: FieldTypeTagging

  /// Creates a wire field.
  ///
  /// - Parameters:
  ///   - value: The value, or `nil` to clear the field.
  ///   - typeTagging: When to write `type`.
  public init(_ value: FieldValue?, typeTagging: FieldTypeTagging = .whenRequired) {
    self.value = value
    self.typeTagging = typeTagging
  }

  /// Decodes a field dictionary.
  ///
  /// - Throws: `DecodingError` for malformed JSON, or ``ConversionError`` when
  ///   the value contradicts its `type` (the same rules as a query response).
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if try container.decodeNil(forKey: .value) {
      self.init(nil)
      return
    }
    let response = try Components.Schemas.FieldValueResponse(from: decoder)
    let fieldName = decoder.codingPath.last?.stringValue ?? ""
    self.init(
      try FieldValue(response, fieldName: fieldName),
      typeTagging: response._type == nil ? .whenRequired : .always
    )
  }

  /// Encodes the field dictionary.
  ///
  /// - Throws: `EncodingError` when a number isn't finite.
  public func encode(to encoder: any Encoder) throws {
    try request(isEncrypted: false).encode(to: encoder)
  }

  /// The generated request payload for this field.
  internal func request(isEncrypted: Bool) -> Components.Schemas.FieldValueRequest {
    guard let value else {
      return .cleared
    }
    var request = Components.Schemas.FieldValueRequest(from: value)
    if typeTagging == .always || isEncrypted, request._type == nil {
      request._type = Components.Schemas.RecordOperation.explicitType(for: value)
    }
    if isEncrypted {
      request.isEncrypted = true
    }
    return request
  }
}
