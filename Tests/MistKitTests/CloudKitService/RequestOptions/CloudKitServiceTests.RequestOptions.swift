//
//  CloudKitServiceTests.RequestOptions.swift
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

extension CloudKitServiceTests {
  /// Coverage for issues #383/#384/#385 (epic #409): the documented request-body options
  /// on records/query, records/modify and records/changes must serialize into the request.
  @Suite("Request Options")
  internal struct RequestOptions {
    private static let database: Database = .public(.prefers(.serverToServer))

    /// Builds a service whose transport records request bodies for later inspection.
    private static func makeService(
      _ provider: ResponseProvider
    ) throws -> CloudKitService {
      try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
        transport: MockTransport(responseProvider: provider)
      )
    }

    /// The first request body sent for `operationID`, decoded as a JSON object. The body is
    /// recorded before the (mock) response is processed, so the call's own result is irrelevant.
    private static func sentBody(
      for operationID: String,
      from provider: ResponseProvider
    ) async throws -> [String: Any] {
      let bodies = await provider.bodies(for: operationID)
      let data = try #require(bodies.compactMap { $0 }.first)
      return try #require(
        try JSONSerialization.jsonObject(with: data) as? [String: Any]
      )
    }

    @Test("records/query serializes zoneWide and numbersAsStrings (#383)")
    internal func queryRequestOptions() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = ResponseProvider.default
      let service = try Self.makeService(provider)

      _ = try? await service.queryRecords(
        MistKit.Query(recordType: "TestRecord"),
        zoneWide: true,
        numbersAsStrings: true,
        database: Self.database
      )

      let body = try await Self.sentBody(for: "queryRecords", from: provider)
      #expect(body["zoneWide"] as? Bool == true)
      #expect(body["numbersAsStrings"] as? Bool == true)
    }

    @Test("records/modify serializes zoneID, desiredKeys and numbersAsStrings (#384)")
    internal func modifyRequestOptions() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = ResponseProvider.default
      let service = try Self.makeService(provider)
      let operation = RecordOperation(
        operationType: .create,
        recordType: "TestRecord",
        recordName: "rec-1",
        fields: ["title": .string("Test")]
      )

      _ = try? await service.modifyRecords(
        [operation],
        zoneID: ZoneID(zoneName: "CustomZone"),
        desiredKeys: ["title"],
        numbersAsStrings: true,
        database: Self.database
      )

      let body = try await Self.sentBody(for: "modifyRecords", from: provider)
      let zoneID = try #require(body["zoneID"] as? [String: Any])
      #expect(zoneID["zoneName"] as? String == "CustomZone")
      #expect(body["desiredKeys"] as? [String] == ["title"])
      #expect(body["numbersAsStrings"] as? Bool == true)
    }

    @Test("records/changes serializes desiredKeys and desiredRecordTypes (#385)")
    internal func changesRequestOptions() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = ResponseProvider.default
      let service = try Self.makeService(provider)

      _ = try? await service.fetchRecordChanges(
        desiredKeys: ["title", "body"],
        desiredRecordTypes: ["Note"],
        database: Self.database
      )

      let body = try await Self.sentBody(for: "fetchRecordChanges", from: provider)
      #expect(body["desiredKeys"] as? [String] == ["title", "body"])
      #expect(body["desiredRecordTypes"] as? [String] == ["Note"])
    }
  }
}
