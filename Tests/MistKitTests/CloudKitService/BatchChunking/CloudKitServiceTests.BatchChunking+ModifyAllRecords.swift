//
//  CloudKitServiceTests.BatchChunking+ModifyAllRecords.swift
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
  /// `modifyAllRecords` reports completed results and unsent operations when
  /// a request fails (MistKit #504).
  @Suite("modifyAllRecords partial failure")
  internal struct ModifyAllRecords {
    @Test("a failing first request reports nothing completed and everything unsent")
    internal func firstRequestFails() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = await Self.provider([Self.throttled()])
      let service = try CloudKitServiceTests.BatchChunking.makeUserService(provider: provider)
      let names = Self.names("n", 5)

      let failure = try await Self.incomplete(Self.operations(names), service: service)

      #expect(failure.completed.isEmpty)
      #expect(Self.recordNames(failure.unsent) == names)
      #expect(failure.underlying.isRetryable)
      #expect(await provider.callCount(for: Self.operationID) == 1)
    }

    @Test("a failing middle request keeps earlier results and reports the rest unsent")
    internal func middleRequestFails() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = await Self.provider([
        try Self.modified(["n0", "n1"]),
        .connectionLost(),
        try Self.modified(["n4"]),
      ])
      let service = try CloudKitServiceTests.BatchChunking.makeUserService(provider: provider)
      let names = Self.names("n", 5)

      let failure = try await Self.incomplete(Self.operations(names), service: service)

      #expect(Self.recordNames(failure.completed) == ["n0", "n1"])
      #expect(Self.recordNames(failure.unsent) == ["n2", "n3", "n4"])
      guard case .networkError(let urlError) = failure.underlying else {
        Issue.record("expected .networkError, got \(failure.underlying)")
        return
      }
      #expect(urlError.code == .networkConnectionLost)
      // The third request is never sent.
      #expect(await provider.callCount(for: Self.operationID) == 2)
    }

    @Test("a failing last request reports only its own operations unsent")
    internal func lastRequestFails() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = await Self.provider([
        try Self.modified(["n0", "n1"]),
        try Self.modified(["n2", "n3"]),
        .authenticationError(),
      ])
      let service = try CloudKitServiceTests.BatchChunking.makeUserService(provider: provider)
      let names = Self.names("n", 5)

      let failure = try await Self.incomplete(Self.operations(names), service: service)

      #expect(Self.recordNames(failure.completed) == ["n0", "n1", "n2", "n3"])
      #expect(Self.recordNames(failure.unsent) == ["n4"])
      guard case .authenticationFailed = failure.underlying else {
        Issue.record("expected .authenticationFailed, got \(failure.underlying)")
        return
      }
      #expect(await provider.callCount(for: Self.operationID) == 3)
    }

    @Test("across zones, completed and unsent follow zone-grouped send order")
    internal func acrossZones() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // Input interleaves zones: t0 d0 t1 d1 t2 d2. Sent as Teams [t0 t1],
      // Teams [t2], default [d0 d1], default [d2]; the third request fails.
      let provider = await Self.provider([
        try Self.modified(["t0", "t1"]),
        try Self.modified(["t2"]),
        .timeout(),
      ])
      let service = try CloudKitServiceTests.BatchChunking.makeUserService(provider: provider)
      let operations = (0..<3).flatMap { index in
        Self.operations(["t\(index)"], in: Self.teams) + Self.operations(["d\(index)"])
      }

      let failure = try await Self.incomplete(
        operations,
        service: service,
        atomicZones: [Self.teams]
      )

      #expect(Self.recordNames(failure.completed) == ["t0", "t1", "t2"])
      #expect(Self.recordNames(failure.unsent) == ["d0", "d1", "d2"])
      // Unsent operations keep the zone they were passed in with.
      #expect(failure.unsent.allSatisfy { $0.zoneID == nil })
      #expect(await provider.callCount(for: Self.operationID) == 3)
    }

    @Test("all requests succeeding returns every result, as before")
    internal func allSucceed() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = await Self.provider([
        try Self.modified(["n0", "n1"]),
        try Self.modified(["n2"]),
      ])
      let service = try CloudKitServiceTests.BatchChunking.makeUserService(provider: provider)

      let results = try await service.modifyAllRecords(
        Self.operations(Self.names("n", 3)),
        database: .private,
        batchSize: 2
      )

      #expect(Self.recordNames(results) == ["n0", "n1", "n2"])
    }
  }
}
