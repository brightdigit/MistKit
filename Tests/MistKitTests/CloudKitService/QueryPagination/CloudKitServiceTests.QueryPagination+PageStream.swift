//
//  CloudKitServiceTests.QueryPagination+PageStream.swift
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

extension CloudKitServiceTests.QueryPagination {
  /// `queryRecordPages` and `modifyAllRecords` (MistKit #499).
  @Suite("Page stream and modifyAllRecords")
  internal struct PageStream {
    private static let query = Query(recordType: "TestRecord")
    private static let database = Database.public(.prefers(.serverToServer))

    private static func pages(
      _ stream: AsyncThrowingStream<QueryResult, any Error>
    ) async throws -> [QueryResult] {
      var pages: [QueryResult] = []
      for try await page in stream {
        pages.append(page)
      }
      return pages
    }

    @Test("yields each page in order and finishes after the last")
    internal func pagesInOrder() async throws {
      let service = try await CloudKitServiceTests.QueryPagination.makePaginatedService(
        pages: [(2, "m1"), (2, "m2"), (1, nil)]
      )
      let pages = try await Self.pages(
        service.queryRecordPages(Self.query, database: Self.database)
      )
      #expect(pages.map(\.records.count) == [2, 2, 1])
      #expect(pages.map(\.continuationMarker) == ["m1", "m2", nil])
    }

    @Test("stops when the server repeats the marker with no records")
    internal func stuckMarker() async throws {
      let service = try await CloudKitServiceTests.QueryPagination.makePaginatedService(
        pages: [(2, "m1"), (0, "m1")]
      )
      let pages = try await Self.pages(
        service.queryRecordPages(Self.query, database: Self.database)
      )
      #expect(pages.map(\.records.count) == [2])
    }

    @Test("an error ends the stream with the CloudKitError")
    internal func errorEnds() async throws {
      let provider = ResponseProvider(
        defaultResponse: .cloudKitError(
          statusCode: 429,
          serverErrorCode: "THROTTLED",
          reason: "slow"
        )
      )
      let service = try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
        transport: MockTransport(responseProvider: provider)
      )
      do {
        _ = try await Self.pages(
          service.queryRecordPages(Self.query, database: Self.database)
        )
        Issue.record("expected the stream to throw")
      } catch let error as CloudKitError {
        #expect(error.isRetryable)
      }
    }

    @Test("modifyAllRecords groups by zone, splits, and sets atomic per zone")
    internal func modifyAll() async throws {
      let transport = RecordingTransport(
        response: .success(body: Data(#"{"records":[]}"#.utf8))
      )
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
      let teams = ZoneID(zoneName: "Teams")
      let operations = (0..<5).map { index in
        ZonedRecordOperation(
          .delete(recordType: "Note", recordName: "n\(index)"),
          in: index.isMultiple(of: 2) ? teams : nil
        )
      }
      _ = try await service.modifyAllRecords(
        operations,
        atomicZones: [teams],
        database: .private,
        batchSize: 2
      )
      var bodies: [[String: Any]] = []
      for sent in await transport.sent {
        let body = try #require(sent.body)
        let json = try JSONSerialization.jsonObject(with: body)
        bodies.append(try #require(json as? [String: Any]))
      }
      // Teams has n0, n2, n4 (two requests); the default zone n1, n3 (one).
      #expect(bodies.map { ($0["operations"] as? [Any])?.count } == [2, 1, 2])
      #expect(bodies.map { $0["atomic"] as? Bool } == [true, true, false])
      #expect(
        bodies.map { ($0["zoneID"] as? [String: Any])?["zoneName"] as? String }
          == ["Teams", "Teams", nil]
      )
    }
  }
}
