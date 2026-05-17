//
//  FetchCallerPhase.swift
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

/// Calls `users/caller`, the user-context endpoint that replaced the deprecated
/// `users/current`.
///
/// CloudKit only accepts this endpoint against the **public database with
/// web-auth credentials**. The runner only schedules this phase when the
/// configured `Credentials` carries web-auth material; the service resolves
/// the right token manager per call.
internal struct FetchCallerPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = UserInfo

  internal static let title = "Fetch caller (current user)"
  internal static let emoji = "👤"
  internal static let apiName = "fetchCaller"

  internal func run(
    input: NoState, context: PhaseContext
  ) async throws -> UserInfo {
    print("\n\(Self.emoji) \(Self.title)")

    let userInfo = try await context.service.fetchCaller()

    print("✅ Caller: \(userInfo.userRecordName)")

    if context.verbose {
      if let firstName = userInfo.firstName { print("   First name: \(firstName)") }
      if let lastName = userInfo.lastName { print("   Last name: \(lastName)") }
    }

    return userInfo
  }
}
