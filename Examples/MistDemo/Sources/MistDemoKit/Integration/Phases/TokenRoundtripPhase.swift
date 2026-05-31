//
//  TokenRoundtripPhase.swift
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

/// Mint an APNs token via `tokens/create`, then register it via
/// `tokens/register` — exercising both token endpoints in one phase (per #53,
/// register is seeded with the token returned by create).
internal struct TokenRoundtripPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Create and register an APNs token"
  internal static let emoji = "🎟️"
  internal static let apiName = "createToken+registerToken"

  internal func run(input: NoState, context: PhaseContext) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    // Reuse one clientId across both halves so the round-trip exercises the
    // CloudKit JS-style "single logical client" attribution path.
    let clientId = UUID().uuidString

    let token = try await context.service.createAPNsToken(
      environment: .development,
      clientId: clientId,
      database: context.database
    )
    if context.verbose {
      print("   ✅ Created APNs token (\(token.apnsToken.prefix(8))…)")
    }

    try await context.service.registerAPNsToken(
      token.apnsToken,
      environment: token.environment,
      clientId: clientId,
      database: context.database
    )
    print("✅ Created and registered an APNs token")

    return NoState()
  }
}
