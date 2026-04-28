//
//  CloudKitService+UserOperations.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
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
  /// Fetch current user information
  public func fetchCurrentUser() async throws(CloudKitError) -> UserInfo {
    do {
      let response = try await client.getCurrentUser(
        .init(
          path: createGetCurrentUserPath(containerIdentifier: containerIdentifier)
        )
      )

      let userData: Components.Schemas.UserResponse =
        try await responseProcessor.processGetCurrentUserResponse(response)
      return UserInfo(from: userData)
    } catch {
      throw mapToCloudKitError(error, context: "fetchCurrentUser")
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
