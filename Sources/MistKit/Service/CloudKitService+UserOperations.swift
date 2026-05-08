//
//  CloudKitService+UserOperations.swift
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
import OpenAPIRuntime

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

#if !os(WASI)
  import OpenAPIURLSession
#endif

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Fetch the caller's (current authenticated user's) information.
  ///
  /// Hits CloudKit's `users/caller` endpoint, which replaces the deprecated
  /// `users/current`. Requires public-database routing with web-auth credentials
  /// (user-context auth); calling against the private database returns
  /// `BAD_REQUEST: endpoint not applicable in the database type`.
  public func fetchCaller() async throws(CloudKitError) -> UserInfo {
    do {
      let response = try await client.getCaller(
        .init(
          path: createGetCallerPath(containerIdentifier: containerIdentifier)
        )
      )

      let userData: Components.Schemas.UserResponse =
        try await responseProcessor.processGetCallerResponse(response)
      return UserInfo(from: userData)
    } catch {
      throw mapToCloudKitError(error, context: "fetchCaller")
    }
  }

  /// Fetch the current authenticated user's information.
  @available(*, deprecated, renamed: "fetchCaller", message: "users/current is deprecated by Apple. Use fetchCaller() instead.")
  public func fetchCurrentUser() async throws(CloudKitError) -> UserInfo {
    try await fetchCaller()
  }

  /// Discover all user identities in the caller's CloudKit address book.
  ///
  /// Hits CloudKit's GET `users/discover` endpoint. Requires public-database
  /// routing with web-auth credentials (user-context auth); only users who have
  /// run the app and granted discoverability are returned.
  ///
  /// > Important: Marked `unavailable` until #28 is resolved. Live testing
  /// > on 2026-05-08 against `iCloud.com.brightdigit.MistDemo` returned
  /// > HTTP 500 from Apple. The GET form of `/users/discover` is referenced
  /// > in CloudKitJS but does not appear in Apple's CloudKit Web Services
  /// > REST documentation, and the live endpoint did not respond
  /// > successfully. The OpenAPI definition, generated client, path
  /// > builder, response processor, and Swift wrapper are all in place;
  /// > unblocking is a one-line `@available` removal once the correct
  /// > REST shape is determined. Tracking:
  /// > [#28](https://github.com/brightdigit/MistKit/issues/28).
  @available(
    *, unavailable,
    message:
      "Not yet ready: live testing on 2026-05-08 returned HTTP 500 from Apple's GET /users/discover. The REST request shape is still under investigation. See #28."
  )
  public func discoverAllUserIdentities() async throws(CloudKitError) -> [UserIdentity] {
    do {
      let response = try await client.discoverAllUserIdentities(
        .init(
          path: createDiscoverAllUserIdentitiesPath(
            containerIdentifier: containerIdentifier
          )
        )
      )

      let discoverData: Components.Schemas.DiscoverResponse =
        try await responseProcessor.processDiscoverAllUserIdentitiesResponse(
          response
        )
      return discoverData.users?.map(UserIdentity.init(from:)) ?? []
    } catch {
      throw mapToCloudKitError(error, context: "discoverAllUserIdentities")
    }
  }

  /// Look up user identities by email address.
  ///
  /// Hits CloudKit's POST `users/lookup/email` endpoint. Each requested email
  /// returns at most one identity in the result array. Requires public-database
  /// routing with web-auth credentials (user-context auth).
  public func lookupUsersByEmail(
    _ emails: [String]
  ) async throws(CloudKitError) -> [UserIdentity] {
    do {
      let response = try await client.lookupUsersByEmail(
        .init(
          path: createLookupUsersByEmailPath(
            containerIdentifier: containerIdentifier
          ),
          body: .json(
            .init(users: emails.map { .init(emailAddress: $0) })
          )
        )
      )

      let discoverData: Components.Schemas.DiscoverResponse =
        try await responseProcessor.processLookupUsersByEmailResponse(response)
      return discoverData.users?.map(UserIdentity.init(from:)) ?? []
    } catch {
      throw mapToCloudKitError(error, context: "lookupUsersByEmail")
    }
  }

  /// Look up user identities by record name (CloudKit user record ID).
  ///
  /// Hits CloudKit's POST `users/lookup/id` endpoint. Requires public-database
  /// routing with web-auth credentials (user-context auth).
  public func lookupUsersByRecordName(
    _ recordNames: [String]
  ) async throws(CloudKitError) -> [UserIdentity] {
    do {
      let response = try await client.lookupUsersByRecordName(
        .init(
          path: createLookupUsersByRecordNamePath(
            containerIdentifier: containerIdentifier
          ),
          body: .json(
            .init(users: recordNames.map { .init(userRecordName: $0) })
          )
        )
      )

      let discoverData: Components.Schemas.DiscoverResponse =
        try await responseProcessor.processLookupUsersByRecordNameResponse(response)
      return discoverData.users?.map(UserIdentity.init(from:)) ?? []
    } catch {
      throw mapToCloudKitError(error, context: "lookupUsersByRecordName")
    }
  }

  /// Discover user identities by email addresses or record names
  public func discoverUserIdentities(
    lookupInfos: [UserIdentityLookupInfo]
  ) async throws(CloudKitError) -> [UserIdentity] {
    do {
      let response = try await client.discoverUserIdentities(
        .init(
          path: createDiscoverUserIdentitiesPath(
            containerIdentifier: containerIdentifier
          ),
          body: .json(
            .init(
              lookupInfos: lookupInfos.map {
                .init(
                  emailAddress: $0.emailAddress,
                  phoneNumber: $0.phoneNumber,
                  userRecordName: $0.userRecordName
                )
              }
            )
          )
        )
      )

      let discoverData: Components.Schemas.DiscoverResponse =
        try await responseProcessor.processDiscoverUserIdentitiesResponse(
          response
        )
      return discoverData.users?.map(UserIdentity.init(from:)) ?? []
    } catch {
      throw mapToCloudKitError(error, context: "discoverUserIdentities")
    }
  }
}
