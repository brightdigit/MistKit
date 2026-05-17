//
//  CloudKitServiceTests.ModifyZones+Validation.swift
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

import Foundation
import Testing

@testable import MistKit

extension CloudKitServiceTests.ModifyZones {
  @Suite("Validation")
  internal struct Validation {
    @Test("modifyZones() throws 400 for empty operations array")
    internal func modifyZonesThrowsForEmptyOperations() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.ModifyZones.makeSuccessfulService()

      await #expect {
        try await service.modifyZones([], database: .private)
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpErrorWithRawResponse(let status, _) = ckError
        else { return false }
        return status == 400
      }
    }

    @Test("modifyZones() throws 400 for operation with empty zoneName")
    internal func modifyZonesThrowsForEmptyZoneName() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.ModifyZones.makeSuccessfulService()

      await #expect {
        try await service.modifyZones(
          [.create(ZoneID(zoneName: "", ownerName: nil))],
          database: .private
        )
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpErrorWithRawResponse(let status, _) = ckError
        else { return false }
        return status == 400
      }
    }

    @Test("modifyZones() throws 400 when any operation has an empty zoneName")
    internal func modifyZonesThrowsForMixedZoneNames() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.ModifyZones.makeSuccessfulService()
      let operations: [ZoneOperation] = [
        .create(ZoneID(zoneName: "Articles", ownerName: nil)),
        .delete(ZoneID(zoneName: "", ownerName: nil)),
      ]

      await #expect {
        try await service.modifyZones(operations, database: .private)
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpErrorWithRawResponse(let status, _) = ckError
        else { return false }
        return status == 400
      }
    }

    @Test("modifyZones() throws 400 for .public database")
    internal func modifyZonesThrowsForPublicDatabase() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.ModifyZones.makeSuccessfulService()

      await #expect {
        try await service.modifyZones(
          [.create(ZoneID(zoneName: "Articles", ownerName: nil))],
          database: .public(.prefers(.serverToServer))
        )
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpErrorWithRawResponse(let status, _) = ckError
        else { return false }
        return status == 400
      }
    }
  }
}
