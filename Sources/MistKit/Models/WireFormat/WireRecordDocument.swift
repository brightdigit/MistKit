//
//  WireRecordDocument.swift
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

/// Records read from any CloudKit Web Services JSON that holds them.
///
/// Decodes, by its shape:
/// - an array of ``WireRecord`` dictionaries;
/// - a query or lookup response, `{"records": […]}` (other keys ignored);
/// - a `records/modify` body, `{"operations": […], "zoneID": {…}}`: the record
///   of each operation except deletes, which name a record without
///   describing it, with the body's `zoneID` for records that give none;
/// - anything else as a single record dictionary.
///
/// ```swift
/// let document = try JSONDecoder().decode(WireRecordDocument.self, from: pasted)
/// let records = document.records
/// ```
public struct WireRecordDocument: Decodable, Hashable, Sendable {
  /// The JSON a document was read from.
  public enum Shape: Sendable, Hashable {
    /// An array of record dictionaries.
    case records
    /// A single record dictionary.
    case record
    /// A query or lookup response, `{"records": […]}`.
    case queryResponse
    /// A `records/modify` body, `{"operations": […]}`.
    case modifyBody
  }

  private enum CodingKeys: String, CodingKey {
    case records
    case operations
    case zoneID
  }

  private struct ModifyOperation: Decodable {
    private enum CodingKeys: String, CodingKey {
      case operationType
      case record
    }

    let record: WireRecord?

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let wireType = try container.decode(
        Components.Schemas.RecordOperation.operationTypePayload.self,
        forKey: .operationType
      )
      record =
        RecordOperation.OperationType(wireType).isDelete
        ? nil : try container.decode(WireRecord.self, forKey: .record)
    }
  }

  /// The records, in order.
  public var records: [WireRecord]
  /// The JSON they were read from.
  public var shape: Shape
  /// A modify body's `zoneID`; `nil` for the other shapes.
  public var zoneID: ZoneID?

  /// Creates a document.
  public init(records: [WireRecord], shape: Shape, zoneID: ZoneID? = nil) {
    self.records = records
    self.shape = shape
    self.zoneID = zoneID
  }

  /// Decodes records from an array, a response, a modify body or a record.
  ///
  /// - Throws: `DecodingError` for malformed JSON, an unknown
  ///   `operationType`, or a ``ConversionError`` (its `underlyingError`) as
  ///   ``WireRecord`` does.
  public init(from decoder: any Decoder) throws {
    if var array = try? decoder.unkeyedContainer() {
      var records: [WireRecord] = []
      while !array.isAtEnd {
        records.append(try array.decode(WireRecord.self))
      }
      self.init(records: records, shape: .records)
      return
    }
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.operations) {
      let operations = try container.decode([ModifyOperation].self, forKey: .operations)
      let schema = try container.decodeIfPresent(
        Components.Schemas.ZoneID.self,
        forKey: .zoneID
      )
      let zoneID = try ConversionFailureReporter.decodingWithoutTrapping(
        at: container.codingPath
      ) {
        try schema.map { schema throws(ConversionError) in try ZoneID(from: schema) }
      }
      let records = operations.compactMap(\.record).map { record in
        var record = record
        record.zoneID = record.zoneID ?? zoneID
        return record
      }
      self.init(records: records, shape: .modifyBody, zoneID: zoneID)
    } else if container.contains(.records) {
      self.init(
        records: try container.decode([WireRecord].self, forKey: .records),
        shape: .queryResponse
      )
    } else {
      self.init(records: [try WireRecord(from: decoder)], shape: .record)
    }
  }

  /// The records as ``RecordInfo``s.
  ///
  /// - Throws: ``ConversionError/recordMissingRecordName`` for a record
  ///   without a name.
  public func recordInfos() throws(ConversionError) -> [RecordInfo] {
    var infos: [RecordInfo] = []
    infos.reserveCapacity(records.count)
    for record in records {
      infos.append(try RecordInfo(record))
    }
    return infos
  }
}
