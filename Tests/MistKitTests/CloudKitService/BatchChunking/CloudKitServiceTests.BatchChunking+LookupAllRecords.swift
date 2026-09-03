//
//  CloudKitServiceTests.BatchChunking+LookupAllRecords.swift
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

extension CloudKitServiceTests.BatchChunking {
  @Suite("lookupAllRecords")
  internal struct LookupAllRecords {
    private static let recordsPerCall = 2

    private static func makeService() throws -> (CloudKitService, ResponseProvider) {
      let provider = ResponseProvider(
        defaultResponse: try .successfulLookupRecordsResponse(recordCount: recordsPerCall)
      )
      let service = try CloudKitServiceTests.BatchChunking.makeUserService(
        provider: provider
      )
      return (service, provider)
    }

    @Test("issues one request and passes results through for a single batch")
    internal func singleBatch() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Self.makeService()
      let names = (0..<5).map { "rec-\($0)" }

      let results = try await service.lookupAllRecords(
        recordNames: names.map(RecordName.init(rawValue:)),
        database: .private
      )

      let count = await provider.callCount(for: "lookupRecords")
      let sizes = CloudKitServiceTests.BatchChunking.itemCounts(
        in: await provider.bodies(for: "lookupRecords"),
        key: "records"
      )
      #expect(count == 1)
      #expect(sizes == [5])
      // The mock returns `recordsPerCall` records per request regardless of
      // input size, so the result count reflects the mock, not `names.count`.
      #expect(results.count == Self.recordsPerCall)
    }

    @Test("accumulates results across multiple batches and preserves order")
    internal func multiBatchAccumulation() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Self.makeService()
      let names = (0..<450).map { "rec-\($0)" }

      let results = try await service.lookupAllRecords(
        recordNames: names.map(RecordName.init(rawValue:)),
        database: .private
      )

      let bodies = await provider.bodies(for: "lookupRecords")
      let sizes = CloudKitServiceTests.BatchChunking.itemCounts(in: bodies, key: "records")
      let order = CloudKitServiceTests.BatchChunking.orderedValues(
        in: bodies,
        key: "records",
        field: "recordName"
      )
      #expect(await provider.callCount(for: "lookupRecords") == 3)
      #expect(sizes == [200, 200, 50])
      #expect(order == names)
      #expect(results.count == 3 * Self.recordsPerCall)
    }

    @Test("custom batchSize controls chunk boundaries")
    internal func customBatchSize() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Self.makeService()
      let names = (0..<5).map { "rec-\($0)" }

      _ = try await service.lookupAllRecords(
        recordNames: names.map(RecordName.init(rawValue:)),
        database: .private,
        batchSize: 2
      )

      let sizes = CloudKitServiceTests.BatchChunking.itemCounts(
        in: await provider.bodies(for: "lookupRecords"),
        key: "records"
      )
      #expect(sizes == [2, 2, 1])
    }

    @Test("batchSize below 1 clamps to 1")
    internal func batchSizeClampsLow() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Self.makeService()
      let names = (0..<3).map { "rec-\($0)" }

      _ = try await service.lookupAllRecords(
        recordNames: names.map(RecordName.init(rawValue:)),
        database: .private,
        batchSize: 0
      )

      let sizes = CloudKitServiceTests.BatchChunking.itemCounts(
        in: await provider.bodies(for: "lookupRecords"),
        key: "records"
      )
      #expect(sizes == [1, 1, 1])
    }

    @Test("batchSize above the cap clamps to maxRecordsPerRequest")
    internal func batchSizeClampsHigh() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Self.makeService()
      let names = (0..<250).map { "rec-\($0)" }

      _ = try await service.lookupAllRecords(
        recordNames: names.map(RecordName.init(rawValue:)),
        database: .private,
        batchSize: 9_999
      )

      let sizes = CloudKitServiceTests.BatchChunking.itemCounts(
        in: await provider.bodies(for: "lookupRecords"),
        key: "records"
      )
      #expect(sizes == [200, 50])
    }

    @Test("empty input issues no requests")
    internal func emptyInput() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Self.makeService()

      let results = try await service.lookupAllRecords(
        recordNames: [],
        database: .private
      )

      #expect(results.isEmpty)
      #expect(await provider.callCount(for: "lookupRecords") == 0)
    }

    @Test("a failing batch throws and stops the loop")
    internal func failingBatchPropagates() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = ResponseProvider(
        defaultResponse: try .successfulLookupRecordsResponse(recordCount: Self.recordsPerCall)
      )
      // First batch succeeds, second fails: the loop must stop on the error
      // rather than issuing the remaining batch.
      await provider.enqueue(
        try .successfulLookupRecordsResponse(recordCount: Self.recordsPerCall),
        for: "lookupRecords"
      )
      await provider.enqueue(.authenticationError(), for: "lookupRecords")
      let service = try CloudKitServiceTests.BatchChunking.makeUserService(
        provider: provider
      )
      let names = (0..<450).map { "rec-\($0)" }

      await #expect(throws: CloudKitError.self) {
        _ = try await service.lookupAllRecords(
          recordNames: names.map(RecordName.init(rawValue:)),
          database: .private
        )
      }
      // Two batches issued (success then failure); the third is never sent.
      #expect(await provider.callCount(for: "lookupRecords") == 2)
    }
  }
}
