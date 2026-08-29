//
//  CloudKitServiceTests.DeleteZone+ErrorHandling.swift
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

extension CloudKitServiceTests.DeleteZone {
  @Suite("Error Handling")
  internal struct ErrorHandling {
    @Test("deleteZone() throws when CloudKit reports the zone was not found")
    internal func deleteZoneReportsPerZoneFailure() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.ModifyZones.makeService(zones: [
        [
          "zoneID": ["zoneName": "Missing", "ownerName": "_defaultOwner"],
          "serverErrorCode": "ZONE_NOT_FOUND",
          "reason": "Zone does not exist",
        ]
      ])

      do {
        try await service.deleteZone(zoneName: "Missing", database: .private)
        Issue.record("expected .zoneOperationFailed")
      } catch let error as CloudKitError {
        guard case .zoneOperationFailed(let failure) = error else {
          Issue.record("expected .zoneOperationFailed, got \(error)")
          return
        }
        #expect(failure.zoneName == "Missing")
        #expect(failure.serverErrorCode == .zoneNotFound)
      }
    }
  }
}
