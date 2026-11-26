//
//  WireRecordDocumentTests.swift
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

/// Reading records from any JSON that holds them (MistKit #503).
@Suite("Wire record document")
internal struct WireRecordDocumentTests {
  private static func document(_ json: String) throws -> WireRecordDocument {
    try JSONDecoder().decode(WireRecordDocument.self, from: Data(json.utf8))
  }

  @Test("an array of records")
  internal func array() throws {
    let document = try Self.document(WireFormatGoldens.misticoRecords)
    #expect(document.shape == .records)
    #expect(
      try document.recordInfos() == [WireFormatSamples.specimen, WireFormatSamples.plain]
    )
  }

  @Test("a single record")
  internal func single() throws {
    let document = try Self.document(WireFormatGoldens.plainReadable)
    #expect(document.shape == .record)
    #expect(try document.recordInfos() == [WireFormatSamples.plain])
  }

  @Test("a query response")
  internal func queryResponse() throws {
    let json = #"""
      {"records":[{"recordName":"a","recordType":"T","fields":{}}],"continuationMarker":"m"}
      """#
    let document = try Self.document(json)
    #expect(document.shape == .queryResponse)
    #expect(document.records.map(\.recordName) == ["a"])
    #expect(document.zoneID == nil)
  }

  @Test("a modify body: deletes skipped, the body's zone filled in")
  internal func modifyBody() throws {
    let document = try Self.document(WireFormatGoldens.misticoModifyOperations)
    #expect(document.shape == .modifyBody)
    #expect(document.zoneID == WireFormatSamples.teams)
    #expect(document.records.map(\.recordName) == ["new-1", "specimen-1"])
    #expect(document.records.allSatisfy { $0.zoneID == WireFormatSamples.teams })
    let update = try #require(document.records.last)
    #expect(update.recordChangeTag == "tag-1")
    #expect(update.clearedFields == ["notes"])
    #expect(update.fields == ["title": .string(.value("Renamed"))])
  }

  @Test("a modify body round-trips as ModifyRecordsRequestBody")
  internal func modifyRequestBody() throws {
    let data = Data(WireFormatGoldens.misticoModifyOperations.utf8)
    let body = try JSONDecoder().decode(ModifyRecordsRequestBody.self, from: data)
    #expect(body.atomic == true)
    #expect(body.operations.map(\.operationType) == [.create, .update, .delete])
    let again = try JSONDecoder().decode(
      ModifyRecordsRequestBody.self,
      from: try JSONEncoder.cloudKitReadable.encode(body)
    )
    #expect(again == body)
    #expect(again.hashValue == body.hashValue)
    #expect(Set(body.operations).count == 3)
  }

  @Test("an unknown operation type is a decoding error")
  internal func unknownOperation() {
    let json = #"{"operations":[{"operationType":"upsert","record":{}}]}"#
    #expect(throws: DecodingError.self) {
      try Self.document(json)
    }
  }
}
