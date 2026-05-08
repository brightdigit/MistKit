//
//  CloudKitServiceTests.LookupZones+ErrorHandling.swift
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

extension CloudKitServiceTests.LookupZones {
  @Suite("Error Handling")
  internal struct ErrorHandling {
    @Test("lookupZones() surfaces a network connection failure as CloudKitError.networkError")
    internal func lookupZonesPropagatesConnectionLost() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.makeService(
        provider: ResponseProvider.connectionLost())
      let zone = ZoneID(zoneName: "_defaultZone", ownerName: nil)

      await #expect {
        _ = try await service.lookupZones(zoneIDs: [zone])
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .networkError(let urlError) = ckError
        else { return false }
        return urlError.code == .networkConnectionLost
      }
    }

    @Test("lookupZones() surfaces a request timeout as CloudKitError.networkError(.timedOut)")
    internal func lookupZonesPropagatesTimeout() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.makeService(provider: ResponseProvider.timeout())
      let zone = ZoneID(zoneName: "_defaultZone", ownerName: nil)

      await #expect {
        _ = try await service.lookupZones(zoneIDs: [zone])
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .networkError(let urlError) = ckError
        else { return false }
        return urlError.code == .timedOut
      }
    }
  }
}
