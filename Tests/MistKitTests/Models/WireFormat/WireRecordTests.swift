//
//  WireRecordTests.swift
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
internal import Testing

@testable import MistKit

/// Whole records in CloudKit Web Services JSON (MistKit #503).
@Suite("Wire record")
internal struct WireRecordTests {
  private static func readable(_ value: some Encodable) throws -> String {
    String(decoding: try JSONEncoder.cloudKitReadable.encode(value), as: UTF8.self)
  }

  private static func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
    try JSONDecoder().decode(type, from: Data(json.utf8))
  }

  @Test("a record round-trips through wire JSON")
  internal func roundTrip() throws {
    let records = [WireFormatSamples.specimen, WireFormatSamples.plain]
    let data = try JSONEncoder.cloudKitReadable.encode(records.map { WireRecord($0) })
    let decoded = try JSONDecoder().decode([WireRecord].self, from: data)
    #expect(try decoded.map { try RecordInfo($0) } == records)
    #expect(decoded.allSatisfy { $0.typeTagging == .always })
    #expect(decoded == records.map { WireRecord($0) })
  }

  @Test("a record encodes byte for byte with sorted keys")
  internal func readableGolden() throws {
    #expect(
      try Self.readable(WireRecord(WireFormatSamples.plain)) == WireFormatGoldens.plainReadable)
  }

  @Test("Mistico's records.json decodes to the same records")
  internal func decodesMisticoGolden() throws {
    let decoded = try Self.decode([WireRecord].self, WireFormatGoldens.misticoRecords)
    #expect(
      try decoded.map { try RecordInfo($0) }
        == [WireFormatSamples.specimen, WireFormatSamples.plain]
    )
  }

  @Test("re-encoding decoded JSON is byte-stable")
  internal func byteStable() throws {
    let decoded = try Self.decode([WireRecord].self, WireFormatGoldens.misticoRecords)
    let first = try Self.readable(decoded)
    let again = try Self.readable(try Self.decode([WireRecord].self, first))
    #expect(first == again)
  }

  @Test("stamps are whole milliseconds; created/modified/deleted only when set")
  internal func stampsAndTombstones() throws {
    let record = WireRecord(
      recordName: "r",
      recordType: nil,
      created: RecordTimestamp(timestamp: Date(timeIntervalSince1970: 1.0004)),
      deleted: true
    )
    let json = try Self.readable(record)
    #expect(json.contains(#""timestamp" : 1000"#))
    #expect(json.contains(#""deleted" : true"#))
    #expect(!json.contains("recordType"))
    #expect(!json.contains("modified"))
    #expect(!(try Self.readable(WireRecord(WireFormatSamples.plain))).contains("deleted"))
    let decoded = try Self.decode(WireRecord.self, json)
    #expect(decoded.deleted)
    #expect(decoded.created?.timestamp == Date(timeIntervalSince1970: 1))
  }

  @Test("cleared and encrypted fields round-trip")
  internal func clearedAndEncrypted() throws {
    let record = WireRecord(
      recordName: nil,
      recordType: "Note",
      fields: ["secret": .string(.value("s"))],
      clearedFields: ["body"],
      encryptedFields: ["secret"],
      typeTagging: .whenRequired
    )
    let json = try Self.readable(record)
    #expect(json.contains(#""body" : {"#))
    #expect(json.contains(#""isEncrypted" : true"#))
    let decoded = try Self.decode(WireRecord.self, json)
    #expect(decoded.clearedFields == ["body"])
    #expect(decoded.encryptedFields == ["secret"])
    #expect(decoded.recordName == nil)
    // An encrypted field always carries `type`.
    #expect(decoded.typeTagging == .always)
  }

  @Test("a record without a name isn't a RecordInfo")
  internal func missingName() {
    #expect(throws: ConversionError.recordMissingRecordName) {
      try RecordInfo(WireRecord(recordName: nil, recordType: "Note"))
    }
  }

  @Test("a zone keeps its owner and type")
  internal func zone() throws {
    let json =
      #"{"recordName":"r","zoneID":{"zoneName":"Teams","ownerRecordName":"_o","#
      + #""zoneType":"REGULAR_CUSTOM_ZONE"}}"#
    let decoded = try Self.decode(WireRecord.self, json)
    #expect(decoded.zoneID?.ownerName == "_o")
    #expect(decoded.zoneID?.zoneType == .regularCustom)
    #expect(decoded.fields.isEmpty)
  }

  @Test("a number that isn't finite fails with the record and field in the path")
  internal func nonFinitePath() throws {
    let record = WireRecord(
      recordName: "r",
      recordType: "Note",
      fields: ["ratio": .double(.value(.nan))]
    )
    let error = try #require(throws: EncodingError.self) {
      try JSONEncoder.cloudKitReadable.encode([record])
    }
    guard case .invalidValue(_, let context) = error else {
      Issue.record("Expected invalidValue, got \(error)")
      return
    }
    #expect(context.codingPath.first?.intValue == 0)
    #expect(context.codingPath.dropFirst().map(\.stringValue) == ["fields", "ratio", "value"])
  }
}
