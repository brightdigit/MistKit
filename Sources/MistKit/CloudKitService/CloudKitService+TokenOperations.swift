//
//  CloudKitService+TokenOperations.swift
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
internal import MistKitOpenAPI

extension CloudKitService {
  /// Mint a CloudKit-managed APNs token for non-device callers.
  ///
  /// The native CloudKit framework doesn't need this — the OS binds the
  /// signed-in iCloud account to APNs automatically. The REST surface has no
  /// such binding, so a CloudKit JS browser client or a server process without a
  /// device token mints one here to use as the destination for
  /// subscription-triggered pushes.
  ///
  /// - Parameters:
  ///   - environment: The APNs environment the token targets.
  ///   - database: The CloudKit database scope.
  /// - Returns: The minted ``APNsTokenResult`` (`apnsToken` + web-push auth
  ///   secret).
  /// - Throws: ``CloudKitError`` if the request fails.
  public func createAPNsToken(
    environment: APNsEnvironment,
    database: Database
  ) async throws(CloudKitError) -> APNsTokenResult {
    do {
      let client = try self.client(for: database)
      let response = try await client.createToken(
        .init(
          path: Operations.createToken.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: self.environment,
            database: database
          ),
          body: .json(
            .init(apnsEnvironment: .init(from: environment))
          )
        )
      )

      let tokenData: Components.Schemas.TokenResponse =
        try await responseProcessor.processCreateTokenResponse(response)
      return try APNsTokenResult(from: tokenData)
    } catch {
      throw mapToCloudKitError(error, context: "createAPNsToken")
    }
  }

  /// Register a device's APNs token so CloudKit pushes subscription-triggered
  /// notifications to it.
  ///
  /// This is the device-side counterpart to
  /// ``createAPNsToken(environment:database:)``: a real iOS/macOS device
  /// registers with APNs the normal way, ships its hex token to your backend,
  /// and the backend registers it here so CloudKit subscriptions in this
  /// container deliver to that token.
  ///
  /// - Parameters:
  ///   - apnsToken: The device's APNs token, as a hex string.
  ///   - database: The CloudKit database scope.
  /// - Throws: ``CloudKitError/badRequest(reason:)`` if `apnsToken` is empty, or
  ///   any error surfaced by the API.
  public func registerAPNsToken(
    _ apnsToken: String,
    database: Database
  ) async throws(CloudKitError) {
    let trimmed = apnsToken.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw CloudKitError.badRequest(reason: "apnsToken must not be empty")
    }

    do {
      let client = try self.client(for: database)
      let response = try await client.registerToken(
        .init(
          path: Operations.registerToken.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
          ),
          body: .json(
            .init(apnsToken: trimmed)
          )
        )
      )

      try await responseProcessor.processRegisterTokenResponse(response)
    } catch {
      throw mapToCloudKitError(error, context: "registerAPNsToken")
    }
  }
}
