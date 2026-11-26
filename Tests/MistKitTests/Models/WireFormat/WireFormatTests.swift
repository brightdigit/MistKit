//
//  WireFormatTests.swift
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

/// The public CloudKit Web Services JSON codecs (MistKit #495) and reference
/// zones (MistKit #497).
@Suite("Wire format")
internal struct WireFormatTests {
  private static func json(_ value: some Encodable) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return String(decoding: try encoder.encode(value), as: UTF8.self)
  }

  private static func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
    try JSONDecoder().decode(type, from: Data(json.utf8))
  }

  @Test("a cleared field encodes as {\"value\": null}")
  internal func clearedField() throws {
    #expect(try Self.json(WireFieldValue(nil)) == #"{"value":null}"#)
    #expect(try Self.decode(WireFieldValue.self, #"{"value":null}"#).value == nil)
  }

  @Test("whenRequired tags only ambiguous scalars; always tags everything")
  internal func typeTagging() throws {
    #expect(try Self.json(WireFieldValue(.string(.value("a")))) == #"{"value":"a"}"#)
    #expect(
      try Self.json(WireFieldValue(.string(.value("a")), typeTagging: .always))
        == #"{"type":"STRING","value":"a"}"#
    )
    #expect(
      try Self.json(WireFieldValue(.double(.value(2)))) == #"{"type":"DOUBLE","value":2}"#
    )
    #expect(
      try Self.json(WireFieldValue(.int64(.list([1, 2])), typeTagging: .always))
        == #"{"type":"INT64_LIST","value":[1,2]}"#
    )
  }

  @Test("decoding recovers ambiguous scalars from type")
  internal func decodeTyped() throws {
    let date = try Self.decode(
      WireFieldValue.self,
      #"{"value":1790000000500,"type":"TIMESTAMP"}"#
    )
    #expect(date.value == .date(.value(Date(timeIntervalSince1970: 1_790_000_000.5))))
    #expect(date.typeTagging == .always)
    let string = try Self.decode(WireFieldValue.self, #"{"value":"x"}"#)
    #expect(string.value == .string(.value("x")))
    #expect(string.typeTagging == .whenRequired)
  }

  @Test("a reference carries zoneID only outside the default zone")
  internal func referenceZone() throws {
    let teams = ZoneID(zoneName: "Teams", ownerName: "_owner1")
    let inTeams = FieldValue.reference(.value(Reference(recordName: "a", zoneID: teams)))
    #expect(
      try Self.json(WireFieldValue(inTeams))
        == #"{"value":{"recordName":"a","zoneID":{"ownerRecordName":"_owner1","zoneName":"Teams"}}}"#
    )
    let inDefault = FieldValue.reference(
      .value(Reference(recordName: "a", zoneID: .defaultZone, action: .deleteSelf))
    )
    #expect(
      try Self.json(WireFieldValue(inDefault))
        == #"{"value":{"action":"DELETE_SELF","recordName":"a"}}"#
    )
    let decoded = try Self.decode(
      WireFieldValue.self,
      #"{"value":{"recordName":"a","zoneID":{"zoneName":"Teams"}},"type":"REFERENCE"}"#
    )
    #expect(decoded.value?.referenceValue?.zoneID == ZoneID(zoneName: "Teams"))
  }

  @Test("a modify body round-trips operations, clears, zone and atomic")
  internal func modifyBodyRoundTrip() throws {
    let body = ModifyRecordsRequestBody(
      operations: [
        .create(recordType: "Note", recordName: "n1", fields: ["title": .string(.value("A"))]),
        .update(
          recordType: "Note",
          recordName: "n2",
          fields: ["title": .string(.value("B"))],
          clearedFields: ["body"],
          recordChangeTag: "t2"
        ),
        .delete(recordType: "Note", recordName: "n3", recordChangeTag: "t3"),
      ],
      zoneID: ZoneID(zoneName: "Teams"),
      atomic: true,
      typeTagging: .always
    )
    let encoded = try Self.json(body)
    #expect(
      encoded
        == #"{"atomic":true,"operations":["#
        + #"{"operationType":"create","record":{"fields":{"title":{"type":"STRING","value":"A"}},"#
        + #""recordName":"n1","recordType":"Note"}},"#
        + #"{"operationType":"update","record":{"fields":{"body":{"value":null},"#
        + #""title":{"type":"STRING","value":"B"}},"recordChangeTag":"t2","#
        + #""recordName":"n2","recordType":"Note"}},"#
        + #"{"operationType":"delete","record":{"recordChangeTag":"t3","recordName":"n3"}}],"#
        + #""zoneID":{"zoneName":"Teams"}}"#
    )
    let decoded = try Self.decode(ModifyRecordsRequestBody.self, encoded)
    #expect(decoded.atomic == true)
    #expect(decoded.zoneID == ZoneID(zoneName: "Teams"))
    #expect(decoded.typeTagging == .always)
    #expect(decoded.operations.map(\.recordName) == ["n1", "n2", "n3"])
    #expect(decoded.operations[1].clearedFields == ["body"])
    #expect(decoded.operations[1].fields["title"] == .string(.value("B")))
    #expect(decoded.operations[2].operationType == .delete)
  }

  @Test("encrypted fields carry isEncrypted and an explicit type")
  internal func encryptedField() throws {
    let operation = WireRecordOperation(
      RecordOperation(
        operationType: .create,
        recordType: "Note",
        recordName: "n1",
        fields: ["secret": .string(.value("s"))],
        encryptedFields: ["secret"]
      )
    )
    let encoded = try Self.json(operation)
    #expect(encoded.contains(#""secret":{"isEncrypted":true,"type":"STRING","value":"s"}"#))
    let decoded = try Self.decode(WireRecordOperation.self, encoded)
    #expect(decoded.operation.encryptedFields == ["secret"])
  }

  @Test("modifyRecords sends cleared fields as null")
  internal func modifyRecordsSendsClears() async throws {
    let transport = RecordingTransport(response: .success(body: Data(#"{"records":[]}"#.utf8)))
    let service = try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(
        apiAuth: APICredentials(
          apiToken: TestConstants.apiToken,
          webAuthToken: TestConstants.webAuthToken
        )
      ),
      transport: transport
    )
    _ = try await service.modifyRecords(
      [
        .update(
          recordType: "Note",
          recordName: "n1",
          fields: [:],
          clearedFields: ["body"],
          recordChangeTag: "t1"
        )
      ],
      database: .private
    )
    let body = try #require(await transport.sent.first?.body)
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    let operations = try #require(json["operations"] as? [[String: Any]])
    let record = try #require(operations.first?["record"] as? [String: Any])
    let fields = try #require(record["fields"] as? [String: Any])
    let cleared = try #require(fields["body"] as? [String: Any])
    #expect(cleared["value"] is NSNull)
  }
}
