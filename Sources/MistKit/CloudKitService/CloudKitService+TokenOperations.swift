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
  private static func resolveClientId(
    _ clientId: String?
  ) throws(CloudKitError) -> String {
    guard let clientId else {
      return UUID().uuidString
    }
    let trimmed = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw CloudKitError.badRequest(reason: "clientId must not be empty when provided")
    }
    return trimmed
  }

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
  ///   - clientId: Logical CloudKit client identifier. CloudKit JS persists
  ///     this across sessions to tie repeat calls to one logical client
  ///     (used by the service for push de-dup). Pass the same value to
  ///     ``registerAPNsToken(_:environment:clientId:database:)`` to keep
  ///     both halves of the round-trip attributed to a single client. When
  ///     `nil`, a fresh UUID is generated per call with no continuity.
  ///   - database: The CloudKit database whose credentials authenticate the
  ///     request. The `tokens/create` endpoint is container-scoped — the
  ///     database is not part of its path — but still needs credentials, so the
  ///     caller picks which database's auth to present.
  /// - Returns: The minted ``APNsTokenResult`` (`apnsToken`, echoed
  ///   `environment`, and `webcourierURL` for browser/Service-Worker push
  ///   delivery).
  /// - Throws: ``CloudKitError/badRequest(reason:)`` if `clientId` is
  ///   provided but empty, or any error surfaced by the API.
  public func createAPNsToken(
    environment: APNsEnvironment,
    clientId: String? = nil,
    database: Database
  ) async throws(CloudKitError) -> APNsTokenResult {
    let resolvedClientId = try Self.resolveClientId(clientId)
    do {
      let client = try self.client(for: database)
      let response = try await client.createToken(
        .init(
          path: Operations.createToken.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: self.environment
          ),
          body: .json(
            .init(
              apnsEnvironment: .init(from: environment),
              clientId: resolvedClientId
            )
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
  /// ``createAPNsToken(environment:clientId:database:)``: a real iOS/macOS
  /// device registers with APNs the normal way, ships its hex token to your
  /// backend, and the backend registers it here so CloudKit subscriptions in
  /// this container deliver to that token.
  ///
  /// - Parameters:
  ///   - apnsToken: The device's APNs token, as a hex string.
  ///   - environment: The APNs environment the token targets (must match the
  ///     environment under which the device registered with APNs).
  ///   - clientId: Logical CloudKit client identifier. Reuse the value passed
  ///     to ``createAPNsToken(environment:clientId:database:)`` to keep both
  ///     calls tied to the same logical client. When `nil`, a fresh UUID is
  ///     generated per call with no continuity to any prior `tokens/create`.
  ///   - database: The CloudKit database whose credentials authenticate the
  ///     request. The `tokens/register` endpoint is container-scoped — the
  ///     database is not part of its path — but still needs credentials, so the
  ///     caller picks which database's auth to present.
  /// - Throws: ``CloudKitError/badRequest(reason:)`` if `apnsToken` is empty
  ///   or `clientId` is provided but empty, or any error surfaced by the API.
  public func registerAPNsToken(
    _ apnsToken: String,
    environment: APNsEnvironment,
    clientId: String? = nil,
    database: Database
  ) async throws(CloudKitError) {
    let trimmed = apnsToken.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw CloudKitError.badRequest(reason: "apnsToken must not be empty")
    }
    let resolvedClientId = try Self.resolveClientId(clientId)

    do {
      let client = try self.client(for: database)
      let response = try await client.registerToken(
        .init(
          path: Operations.registerToken.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: self.environment
          ),
          body: .json(
            .init(
              apnsEnvironment: .init(from: environment),
              apnsToken: trimmed,
              clientId: resolvedClientId
            )
          )
        )
      )

      try await responseProcessor.processRegisterTokenResponse(response)
    } catch {
      throw mapToCloudKitError(error, context: "registerAPNsToken")
    }
  }
}
