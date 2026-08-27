//
//  CloudKitServiceTests.Sharing.swift
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

internal import Foundation
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.Sharing {
  @Suite(
    "CloudKitService acceptShares (records/accept)",
    .enabled(if: Platform.isCryptoAvailable)
  )
  internal struct Accept {
    private typealias Helper = CloudKitServiceTests.Sharing

    @Test("acceptShares reports the caller's resulting participation")
    internal func acceptReportsParticipation() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Helper.makeServiceWithProvider(responsesByOperation: [
        "acceptShares": try Helper.shortGUIDResponse(results: [
          Helper.shortGUIDResult(value: "guid-1", participantStatus: "ACCEPTED")
        ])
      ])

      let result = try #require(
        try await service.acceptShares([ShortGUID(value: "guid-1")]).first
      )
      #expect(result.participantStatus == .accepted)
      #expect(result.participantPermission == .readWrite)
      #expect(result.share?.recordType == ShareInfo.recordType)

      let bodies = await provider.bodies(for: "acceptShares").compactMap { $0 }
      let body = try #require(bodies.first)
      let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
      let sent = try #require(json?["shortGUIDs"] as? [[String: Any]])
      #expect(sent.map { $0["value"] as? String } == ["guid-1"])
    }

    @Test("acceptShares maps results in request order")
    internal func acceptMapsResultsInOrder() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "acceptShares": try Helper.shortGUIDResponse(results: [
          Helper.shortGUIDResult(value: "guid-1"),
          Helper.shortGUIDResult(value: "guid-2"),
        ])
      ])

      let results = try await service.acceptShares([
        ShortGUID(value: "guid-1"),
        ShortGUID(value: "guid-2"),
      ])
      #expect(results.map(\.shortGUID.value) == ["guid-1", "guid-2"])
    }

    @Test("acceptShares throws on a top-level BAD_REQUEST")
    internal func acceptThrowsOnBadRequest() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "acceptShares": .cloudKitError(
          statusCode: 400,
          serverErrorCode: "BAD_REQUEST",
          reason: "share already accepted"
        )
      ])

      let error = await #expect(throws: CloudKitError.self) {
        _ = try await service.acceptShares([ShortGUID(value: "guid-1")])
      }
      guard case .badRequest(let reason) = error else {
        Issue.record("Expected .badRequest, got \(String(describing: error))")
        return
      }
      #expect(reason == "share already accepted")
    }
  }
}
