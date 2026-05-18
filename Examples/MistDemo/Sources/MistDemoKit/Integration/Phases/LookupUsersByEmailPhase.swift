//
//  LookupUsersByEmailPhase.swift
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

/// Calls POST `/users/lookup/email`.
///
/// Prefers the email supplied via `PhaseContext.lookupEmail`
/// (`--lookup-email` / `CLOUDKIT_LOOKUP_EMAIL`) since CloudKit only resolves
/// addresses that belong to iCloud accounts discoverable to the caller. Falls
/// back to the caller's own email when the user-context endpoint exposes it,
/// and skips otherwise — `users/caller` doesn't always return an address.
internal struct LookupUsersByEmailPhase: IntegrationPhase {
  internal typealias Input = UserInfo
  internal typealias Output = NoState

  internal static let title = "Lookup users by email"
  internal static let emoji = "📧"
  internal static let apiName = "lookupUsersByEmail"

  internal func run(
    input: UserInfo, context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    let email: String
    let source: String
    if let configured = context.lookupEmail, !configured.isEmpty {
      email = configured
      source = "configured --lookup-email"
    } else if let callerEmail = input.emailAddress, !callerEmail.isEmpty {
      email = callerEmail
      source = "caller's own address"
    } else {
      print(
        """
        ⏭️  Skipping — no email available. Set --lookup-email or \
        CLOUDKIT_LOOKUP_EMAIL to exercise this phase.
        """
      )
      return NoState()
    }

    if context.verbose {
      print("   Looking up: \(email) (\(source))")
    }

    let identities = try await context.service.lookupUsersByEmail([email])

    print("✅ Looked up \(identities.count) identit\(identities.count == 1 ? "y" : "ies") by email")

    if context.verbose {
      for identity in identities {
        if let name = identity.userRecordName { print("   - \(name)") }
      }
    }

    return NoState()
  }
}
