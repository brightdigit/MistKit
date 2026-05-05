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

import Foundation
import MistKit

struct DiscoverUserIdentitiesPhase: IntegrationPhase {
  typealias Input = String
  typealias Output = Void

  let title = "Discover user identities"
  let emoji = "👥"
  let apiName = "discoverUserIdentities"

  func extractInput(from state: PhaseState) throws -> String {
    guard let user = state.currentUser else {
      throw IntegrationTestError.missingPhaseState("currentUser")
    }
    return user.userRecordName
  }

  func run(input: String, context: PhaseContext) async throws {
    print("\n\(emoji) \(title)")

    let lookupInfos = [UserIdentityLookupInfo(userRecordName: input)]
    let identities = try await context.service.discoverUserIdentities(lookupInfos: lookupInfos)

    print("✅ Discovered \(identities.count) user identit\(identities.count == 1 ? "y" : "ies")")

    if context.verbose {
      for identity in identities {
        if let name = identity.userRecordName { print("   - \(name)") }
      }
    }
  }
}
