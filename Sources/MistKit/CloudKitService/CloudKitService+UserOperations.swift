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
internal import MistKitOpenAPI
import OpenAPIRuntime

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

#if !os(WASI)
  import OpenAPIURLSession
#endif

extension CloudKitService {
  /// Fetch the caller's (current authenticated user's) information.
  ///
  /// Hits CloudKit's `users/caller` endpoint, which replaces the deprecated
  /// `users/current`. Routed against the public database with web-auth
  /// credentials — calling against private/shared returns
  /// `BAD_REQUEST: endpoint not applicable in the database type`, so the
  /// database is fixed in the path and not exposed to callers. The service's
  /// `Credentials` must include an `apiAuth` with a `webAuthToken`.
  public func fetchCaller() async throws(CloudKitError) -> UserInfo {
    do {
      let client = try self.client(for: .public(.requires(.webAuth)))
      let response = try await client.getCaller(
        .init(
          path: Operations.getCaller.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: .public(.requires(.webAuth))
          )
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
  @available(
    *, deprecated, renamed: "fetchCaller",
    message: "users/current is deprecated by Apple. Use fetchCaller() instead."
  )
  public func fetchCurrentUser() async throws(CloudKitError) -> UserInfo {
    try await fetchCaller()
  }

  /// Look up user identities by email address.
  ///
  /// Hits CloudKit's POST `users/lookup/email` endpoint. Each requested email
  /// returns at most one identity in the result array. Routed against the
  /// public database with web-auth credentials.
  public func lookupUsersByEmail(
    _ emails: [String]
  ) async throws(CloudKitError) -> [UserIdentity] {
    do {
      let client = try self.client(for: .public(.requires(.webAuth)))
      let response = try await client.lookupUsersByEmail(
        .init(
          path: Operations.lookupUsersByEmail.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: .public(.requires(.webAuth))
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
  /// Hits CloudKit's POST `users/lookup/id` endpoint. Routed against the
  /// public database with web-auth credentials.
  public func lookupUsersByRecordName(
    _ recordNames: [String]
  ) async throws(CloudKitError) -> [UserIdentity] {
    do {
      let client = try self.client(for: .public(.requires(.webAuth)))
      let response = try await client.lookupUsersByRecordName(
        .init(
          path: Operations.lookupUsersByRecordName.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: .public(.requires(.webAuth))
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

  /// Discover user identities by email addresses or record names.
  ///
  /// Hits CloudKit's POST `users/discover` endpoint. Routed against the public
  /// database with web-auth credentials.
  public func discoverUserIdentities(
    lookupInfos: [UserIdentityLookupInfo]
  ) async throws(CloudKitError) -> [UserIdentity] {
    do {
      let client = try self.client(for: .public(.requires(.webAuth)))
      let response = try await client.discoverUserIdentities(
        .init(
          path: Operations.discoverUserIdentities.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: .public(.requires(.webAuth))
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
