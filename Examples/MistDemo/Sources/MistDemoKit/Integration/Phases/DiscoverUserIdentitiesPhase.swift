//
//  DiscoverUserIdentitiesPhase.swift
//  MistDemo
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
internal import MistKit

/// Calls POST `/users/discover` to look up specific user identities.
///
/// Requires public-database web-auth (user-context) credentials. The runner
/// only schedules this phase when the configured `Credentials` carries
/// web-auth material; the service resolves the right token manager per call.
internal struct DiscoverUserIdentitiesPhase: IntegrationPhase {
  internal typealias Input = UserInfo
  internal typealias Output = NoState

  internal static let title = "Discover user identities"
  internal static let emoji = "👥"
  internal static let apiName = "discoverUserIdentities"

  internal func run(
    input: UserInfo, context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    let lookupInfos = [UserIdentityLookupInfo(userRecordName: input.userRecordName)]
    let identities = try await context.service.discoverUserIdentities(
      lookupInfos: lookupInfos
    )

    print("✅ Discovered \(identities.count) user identit\(identities.count == 1 ? "y" : "ies")")

    if context.verbose {
      for identity in identities {
        if let name = identity.userRecordName { print("   - \(name)") }
      }
    }

    return NoState()
  }
}
