//
//  CloudKitServiceTests.CreateZone+ErrorHandling.swift
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

extension CloudKitServiceTests.CreateZone {
  @Suite("Error Handling")
  internal struct ErrorHandling {
    @Test("createZone() throws .invalidResponse when server returns no zones")
    internal func createZoneEmptyResponseThrows() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.CreateZone.makeEmptyResponseService()

      await #expect(throws: CloudKitError.self) {
        _ = try await service.createZone(
          zoneName: "Articles",
          database: .private
        )
      }
    }

    @Test("createZone() surfaces the per-zone failure rather than .invalidResponse")
    internal func createZoneSurfacesZoneOperationFailure() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.ModifyZones.makeService(zones: [
        [
          "zoneID": ["zoneName": "Articles", "ownerName": "_defaultOwner"],
          "serverErrorCode": "EXISTS",
          "reason": "Zone already exists",
        ]
      ])

      do {
        _ = try await service.createZone(zoneName: "Articles", database: .private)
        Issue.record("expected .zoneOperationFailed")
      } catch let error as CloudKitError {
        guard case .zoneOperationFailed(let failure) = error else {
          Issue.record("expected .zoneOperationFailed, got \(error)")
          return
        }
        #expect(failure.zoneName == "Articles")
        #expect(failure.serverErrorCode == .exists)
        #expect(failure.reason == "Zone already exists")
      }
    }
  }
}
