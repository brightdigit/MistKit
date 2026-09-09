//
//  CloudKitServiceTests.ZoneOwnerWireKey+WireFormat.swift
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

extension CloudKitServiceTests.ZoneOwnerWireKey {
  /// Pins the on-the-wire owner key inside `zoneID` objects (issue #444).
  ///
  /// Apple's Zone ID Dictionary and live responses use `ownerRecordName`, not
  /// the mistaken `ownerName` key MistKit previously emitted.
  @Suite("ZoneID Wire Format", .disabled(if: Platform.isWindowsSwift62))
  internal struct WireFormat {
    private static let database: Database = .private

    private static func makeService(
      _ provider: ResponseProvider
    ) throws -> CloudKitService {
      try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(
          apiAuth: APICredentials(
            apiToken: TestConstants.apiToken,
            webAuthToken: TestConstants.webAuthToken
          )
        ),
        transport: MockTransport(responseProvider: provider)
      )
    }

    private static func sentBody(
      for operationID: String,
      from provider: ResponseProvider,
      at index: Int = 0
    ) async throws -> [String: Any] {
      let bodies = await provider.bodies(for: operationID).compactMap { $0 }
      let data = try #require(bodies.dropFirst(index).first)
      return try #require(
        try JSONSerialization.jsonObject(with: data) as? [String: Any]
      )
    }

    @Test("queryRecords() encodes ownerRecordName, never ownerName")
    internal func queryEncodesOwnerRecordName() async throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("CloudKitService is not available on this operating system.")
          return
        }
        let provider = ResponseProvider.successfulQuery()
        let service = try Self.makeService(provider)

        _ = try await service.queryRecords(
          MistKit.Query(recordType: "TestRecord"),
          zoneID: ZoneID(zoneName: "SharedZone", ownerName: "_owner-record-name"),
          database: Self.database
        )

        let body = try await Self.sentBody(for: "queryRecords", from: provider)
        let zoneID = try #require(body["zoneID"] as? [String: Any])
        #expect(zoneID["ownerRecordName"] as? String == "_owner-record-name")
        #expect(zoneID["ownerName"] == nil)
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }

    @Test("modifyZones() encodes ownerRecordName inside each operation's zoneID")
    internal func modifyZonesEncodesOwnerRecordName() async throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("CloudKitService is not available on this operating system.")
          return
        }
        let provider = try ResponseProvider.successfulModifyZones(zoneCount: 1)
        let service = try Self.makeService(provider)

        _ = try await service.modifyZones(
          [.create(ZoneID(zoneName: "Shared", ownerName: "other-user"))],
          database: Self.database
        )

        let body = try await Self.sentBody(for: "modifyZones", from: provider)
        let operations = try #require(body["operations"] as? [[String: Any]])
        let operation = try #require(operations.first)
        let zone = try #require(operation["zone"] as? [String: Any])
        let zoneID = try #require(zone["zoneID"] as? [String: Any])
        #expect(zoneID["ownerRecordName"] as? String == "other-user")
        #expect(zoneID["ownerName"] == nil)
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }
  }
}
