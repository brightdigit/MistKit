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
    "CloudKitService resolveShares (records/resolve)",
    .enabled(if: Platform.isCryptoAvailable)
  )
  internal struct Resolve {
    private typealias Helper = CloudKitServiceTests.Sharing

    @Test("resolveShares maps every field of a ShortGUID Result")
    internal func resolveMapsResultFields() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "resolveShortGUIDs": try Helper.shortGUIDResponse(results: [
          Helper.shortGUIDResult(value: "guid-1")
        ])
      ])

      let results = try await service.resolveShares([ShortGUIDDictionary(value: "guid-1")])

      #expect(results.count == 1)
      let result = try #require(results.first)
      #expect(result.shortGUID.value == "guid-1")
      #expect(result.shortGUID.shouldFetchRootRecord == true)
      #expect(result.containerIdentifier == TestConstants.serviceContainerIdentifier)
      #expect(result.databaseScope == .shared)
      #expect(result.environment == .development)
      #expect(result.zoneID?.zoneName == "SharedZone")
      #expect(result.zoneID?.ownerName == "_owner")
      #expect(result.rootRecordName == "root-guid-1")
      #expect(result.rootRecord?.recordName == "root-guid-1")
      #expect(result.rootRecord?.recordType == "Note")
      #expect(result.share?.recordType == ShareInfo.recordType)
      #expect(result.ownerIdentity?.userRecordName == .recordName("_owner"))
      #expect(result.participantPermission == .readWrite)
      #expect(result.participantStatus == .accepted)
      #expect(result.participantType == .user)
      #expect(result.webpageURL == "https://www.icloud.com/share/guid-1")
      #expect(result.potentialMatchList.isEmpty)
    }

    @Test("resolveShares sends shortGUIDs in request order")
    internal func resolveSendsShortGUIDsInOrder() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Helper.makeServiceWithProvider(responsesByOperation: [
        "resolveShortGUIDs": try Helper.shortGUIDResponse(results: [
          Helper.shortGUIDResult(value: "guid-1"),
          Helper.shortGUIDResult(value: "guid-2"),
        ])
      ])

      let results = try await service.resolveShares([
        ShortGUIDDictionary(
          value: "guid-1",
          shouldFetchRootRecord: true,
          rootRecordDesiredKeys: ["title"]
        ),
        ShortGUIDDictionary(value: "guid-2"),
      ])

      #expect(results.map(\.shortGUID.value) == ["guid-1", "guid-2"])

      let bodies = await provider.bodies(for: "resolveShortGUIDs").compactMap { $0 }
      let body = try #require(bodies.first)
      let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
      let sent = try #require(json?["shortGUIDs"] as? [[String: Any]])
      #expect(sent.count == 2)
      #expect(sent[0]["value"] as? String == "guid-1")
      #expect(sent[0]["shouldFetchRootRecord"] as? Bool == true)
      #expect(sent[0]["rootRecordDesiredKeys"] as? [String] == ["title"])
      #expect(sent[1]["value"] as? String == "guid-2")
      // Omitted optionals must not be sent as nulls.
      #expect(sent[1]["shouldFetchRootRecord"] == nil)
    }

    @Test("resolveShares omits the root record when not requested")
    internal func resolveWithoutRootRecord() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "resolveShortGUIDs": try Helper.shortGUIDResponse(results: [
          Helper.shortGUIDResult(value: "guid-1", includeRootRecord: false)
        ])
      ])

      let result = try #require(
        try await service.resolveShares([ShortGUIDDictionary(value: "guid-1")]).first
      )
      #expect(result.rootRecord == nil)
      // The root record *name* is still reported.
      #expect(result.rootRecordName == "root-guid-1")
    }

    @Test("resolveShares surfaces a potential match list for an ambiguous caller")
    internal func resolveSurfacesPotentialMatches() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "resolveShortGUIDs": try Helper.shortGUIDResponse(results: [
          Helper.ambiguousResult(value: "guid-amb")
        ])
      ])

      let result = try #require(
        try await service.resolveShares([ShortGUIDDictionary(value: "guid-amb")]).first
      )
      #expect(result.participantStatus == .invited)
      #expect(result.potentialMatchList.count == 2)
      #expect(result.potentialMatchList.first?.participantId == "candidate-1")
      #expect(
        result.potentialMatchList.first?.contactInformation?.emailAddress
          == "one@example.com"
      )
      #expect(
        result.potentialMatchList.last?.contactInformation?.phoneNumber == "+15550100"
      )
    }

    @Test("resolveShares returns an empty array when results are absent")
    internal func resolveHandlesMissingResults() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "resolveShortGUIDs": try Helper.shortGUIDResponse(results: [])
      ])

      let results = try await service.resolveShares([ShortGUIDDictionary(value: "guid-1")])
      #expect(results.isEmpty)
    }

    @Test("resolveShares throws on a top-level BAD_REQUEST")
    internal func resolveThrowsOnBadRequest() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "resolveShortGUIDs": .cloudKitError(
          statusCode: 400,
          serverErrorCode: "BAD_REQUEST",
          reason: "invalid shortGUID"
        )
      ])

      let error = await #expect(throws: CloudKitError.self) {
        _ = try await service.resolveShares([ShortGUIDDictionary(value: "nope")])
      }
      guard case .badRequest(let reason) = error else {
        Issue.record("Expected .badRequest, got \(String(describing: error))")
        return
      }
      #expect(reason == "invalid shortGUID")
    }
  }
}
