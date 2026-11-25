//
//  SchemaSourceTests+Inferred.swift
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

extension SchemaSourceTests {
  @Suite("Inferred")
  internal struct Inferred {
    private static func field(_ name: String, _ type: FieldType) -> SchemaField {
      SchemaField(name: name, type: SchemaFieldType(type))
    }

    private static func source(
      _ provider: ResponseProvider,
      recordTypes: [String] = ["Player"]
    ) throws -> InferredSchemaSource {
      InferredSchemaSource(
        service: try SchemaSourceTests.service(provider),
        database: .public(.prefers(.serverToServer)),
        recordTypes: recordTypes
      )
    }

    private static func provider(_ json: String) -> ResponseProvider {
      ResponseProvider(defaultResponse: SchemaSourceTests.queryResponse(json))
    }

    @Test("infers sorted, unindexed fields from a query, with no guesses")
    internal func fromQuery() async throws {
      let provider = Self.provider(SchemaFixtures.inferredQueryPlayer)
      let inferred = try await Self.source(provider).loadInferredSchema()
      let player = try #require(inferred.schema.recordType(named: "Player"))
      #expect(
        player.fields == [
          Self.field("avatar", .asset),
          Self.field("country", .string),
          Self.field("displayName", .string),
          Self.field("friends", .list(.reference)),
          Self.field("handle", .string),
          Self.field("home", .location),
          Self.field("lastSeen", .timestamp),
          Self.field("rating", .int64),
          Self.field("settings", .bytes),
          // An empty list, typed by its `STRING_LIST` tag.
          Self.field("titles", .list(.string)),
          Self.field("winRate", .double),
        ]
      )
      #expect(player.grants.isEmpty)
      #expect(inferred.schema.roles.isEmpty)
      #expect(inferred.notices.isEmpty)
      #expect(await provider.callCount(for: "queryRecords") == 1)
    }

    @Test("queries the record type for one full page")
    internal func request() async throws {
      let provider = Self.provider(SchemaFixtures.inferredQueryPlayer)
      _ = try await Self.source(provider).loadSchema()
      let body = try #require(await provider.bodies(for: "queryRecords").compactMap { $0 }.first)
      let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
      let query = try #require(json["query"] as? [String: Any])
      #expect(query["recordType"] as? String == "Player")
      #expect(json["resultsLimit"] as? Int == CloudKitService.maxRecordsPerRequest)
    }

    @Test("infers a recorded Player page's columns")
    internal func fromRecordedQuery() async throws {
      let source = try Self.source(Self.provider(SchemaFixtures.recordedFirstPage))
      let inferred = try await source.loadInferredSchema()
      #expect(
        inferred.schema.recordType(named: "Player")?.fields == [
          Self.field("country", .string),
          Self.field("displayName", .string),
          Self.field("gamesPlayed", .int64),
          Self.field("handle", .string),
          Self.field("lastSeen", .timestamp),
          Self.field("rating", .int64),
        ]
      )
      #expect(inferred.notices.isEmpty)
    }

    @Test("a record type with no records has no fields, and says so")
    internal func noRecords() async throws {
      let inferred = try await Self.source(
        Self.provider(#"{"records": []}"#),
        recordTypes: ["Ghost"]
      )
      .loadInferredSchema()
      #expect(inferred.schema.recordTypes == [SchemaRecordType(name: "Ghost")])
      #expect(inferred.notices == [.noRecords(recordType: "Ghost")])
    }

    @Test("a record type named twice is queried once")
    internal func duplicateNames() async throws {
      let provider = Self.provider(SchemaFixtures.inferredQueryPlayer)
      let schema = try await Self.source(provider, recordTypes: ["Player", "Player"])
        .loadSchema()
      #expect(schema.recordTypes.map(\.name) == ["Player"])
      #expect(await provider.callCount(for: "queryRecords") == 1)
    }

    @Test("with no record types to query, it throws noRecordTypes and sends nothing")
    internal func noRecordTypes() async throws {
      let provider = Self.provider(SchemaFixtures.inferredQueryPlayer)
      await #expect {
        _ = try await Self.source(provider, recordTypes: []).loadSchema()
      } throws: { error in
        guard case .noRecordTypes = error as? SchemaSourceError else {
          return false
        }
        return true
      }
      #expect(await provider.callCount(for: "queryRecords") == 0)
    }

    @Test("a query error is a CloudKitError")
    internal func queryError() async throws {
      let source = try Self.source(ResponseProvider.authenticationError())
      await #expect(throws: CloudKitError.self) {
        try await source.loadSchema()
      }
    }

    @Test("never asks for a reload")
    internal func noReloads() async throws {
      let source = try Self.source(Self.provider(SchemaFixtures.inferredQueryPlayer))
      var changes = source.schemaChanges().makeAsyncIterator()
      #expect(await changes.next() == nil)
    }
  }
}
