//
//  ModifyRecordsRequestBody.swift
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

/// A `records/modify` request body in CloudKit Web Services JSON:
/// `{"operations": […], "zoneID": {…}, "atomic": …}`.
///
/// What ``CloudKitService/modifyRecords(_:atomic:zoneID:desiredKeys:numbersAsStrings:database:)``
/// sends, for callers that show, export or replay the request. Each operation
/// is a ``WireRecordOperation``; `zoneID` and `atomic` are omitted when `nil`.
public struct ModifyRecordsRequestBody: Codable, Hashable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case operations
    case zoneID
    case atomic
  }

  /// The operations, in order.
  public var operations: [RecordOperation]
  /// The zone every operation is in; `nil` for the default zone.
  public var zoneID: ZoneID?
  /// Whether CloudKit applies the operations all or nothing.
  public var atomic: Bool?
  /// When field dictionaries carry `type`.
  public var typeTagging: FieldTypeTagging

  /// Creates a body.
  public init(
    operations: [RecordOperation],
    zoneID: ZoneID? = nil,
    atomic: Bool? = nil,
    typeTagging: FieldTypeTagging = .whenRequired
  ) {
    self.operations = operations
    self.zoneID = zoneID
    self.atomic = atomic
    self.typeTagging = typeTagging
  }

  /// Decodes a body.
  ///
  /// - Throws: `DecodingError` as ``WireRecordOperation`` does, or
  ///   `DecodingError.dataCorrupted` with a ``ConversionError`` as its
  ///   `underlyingError` for an unknown `zoneType`.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let operations = try container.decode([WireRecordOperation].self, forKey: .operations)
    let zoneID = try container.decodeIfPresent(
      Components.Schemas.ZoneID.self,
      forKey: .zoneID
    )
    let converted = try ConversionFailureReporter.decodingWithoutTrapping(
      at: container.codingPath
    ) {
      try zoneID.map { schema throws(ConversionError) in try ZoneID(from: schema) }
    }
    self.init(
      operations: operations.map(\.operation),
      zoneID: converted,
      atomic: try container.decodeIfPresent(Bool.self, forKey: .atomic),
      typeTagging: operations.contains { $0.typeTagging == .always } ? .always : .whenRequired
    )
  }

  /// Encodes the body.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(
      operations.map { WireRecordOperation($0, typeTagging: typeTagging) },
      forKey: .operations
    )
    try container.encodeIfPresent(
      zoneID.map(Components.Schemas.ZoneID.init(from:)),
      forKey: .zoneID
    )
    try container.encodeIfPresent(atomic, forKey: .atomic)
  }
}
