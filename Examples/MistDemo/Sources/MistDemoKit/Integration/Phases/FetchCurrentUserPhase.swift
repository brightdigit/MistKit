//
//  FetchCurrentUserPhase.swift
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

struct FetchCurrentUserPhase: IntegrationPhase {
  typealias Input = Void
  typealias Output = UserInfo

  let title = "Fetch current user"
  let emoji = "👤"
  let apiName = "fetchCurrentUser"

  func apply(output: UserInfo, to state: inout PhaseState) {
    state.currentUser = output
  }

  func run(input: Void, context: PhaseContext) async throws -> UserInfo {
    print("\n\(emoji) \(title)")

    let userInfo = try await context.service.fetchCurrentUser()

    print("✅ Current user: \(userInfo.userRecordName)")

    if context.verbose {
      if let firstName = userInfo.firstName { print("   First name: \(firstName)") }
      if let lastName = userInfo.lastName { print("   Last name: \(lastName)") }
    }

    return userInfo
  }
}
