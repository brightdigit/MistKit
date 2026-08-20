//
//  CloudKitService+ShareOperations.swift
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

internal import MistKitOpenAPI

extension CloudKitService {
  /// Resolve share short GUIDs into information about the shared records
  /// (`records/resolve`).
  ///
  /// Given the short GUIDs carried by share URLs, returns the root record,
  /// the governing `cloudKit.share` record, the owner's identity, and the
  /// caller's participation in each share. Set
  /// ``ShortGUID/shouldFetchRootRecord`` to have CloudKit include the root
  /// record itself, optionally narrowed by
  /// ``ShortGUID/rootRecordDesiredKeys``.
  ///
  /// Routed against the public database with web-auth credentials — Apple's
  /// reference fixes the path's database scope to `public`, and resolution is
  /// performed on behalf of the *current* user, so the database is not exposed
  /// to callers. The service's `Credentials` must include an `apiAuth` with a
  /// `webAuthToken`.
  ///
  /// - Parameter shortGUIDs: The short GUIDs identifying the shares to resolve.
  /// - Returns: One ``ShareRecordInfo`` per requested short GUID, in request
  ///   order.
  /// - Throws: ``CloudKitError``. The endpoint validates the whole request, so
  ///   a bad short GUID fails the entire call rather than producing a per-item
  ///   failure.
  public func resolveShares(
    _ shortGUIDs: [ShortGUID]
  ) async throws(CloudKitError) -> [ShareRecordInfo] {
    do {
      let client = try self.client(for: .public(.requires(.webAuth)))
      let response = try await client.resolveShortGUIDs(
        .init(
          path: Operations.resolveShortGUIDs.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: .public(.requires(.webAuth))
          ),
          body: .json(
            .init(shortGUIDs: shortGUIDs.map(Components.Schemas.ShortGUID.init(from:)))
          )
        )
      )

      let resolveData: Components.Schemas.ShortGUIDResultResponse =
        try await responseProcessor.processResolveShortGUIDsResponse(response)
      return try (resolveData.results ?? []).map(ShareRecordInfo.init(from:))
    } catch {
      throw mapToCloudKitError(error, context: "resolveShares")
    }
  }

  /// Accept shares on behalf of the current user (`records/accept`).
  ///
  /// Accepts each share identified by a short GUID, adding the caller as a
  /// participant. The response mirrors ``resolveShares(_:)``, reporting the
  /// caller's resulting ``ShareRecordInfo/participantStatus`` and
  /// ``ShareRecordInfo/participantPermission`` for each share.
  ///
  /// Routed against the public database with web-auth credentials — there is
  /// no current user to accept on behalf of without web-auth, so the database
  /// is not exposed to callers. The service's `Credentials` must include an
  /// `apiAuth` with a `webAuthToken`.
  ///
  /// - Parameter shortGUIDs: The short GUIDs identifying the shares to accept.
  /// - Returns: One ``ShareRecordInfo`` per requested short GUID, in request
  ///   order.
  /// - Throws: ``CloudKitError``. The endpoint validates the whole request, so
  ///   a bad or already-accepted short GUID fails the entire call rather than
  ///   producing a per-item failure.
  public func acceptShares(
    _ shortGUIDs: [ShortGUID]
  ) async throws(CloudKitError) -> [ShareRecordInfo] {
    do {
      let client = try self.client(for: .public(.requires(.webAuth)))
      let response = try await client.acceptShares(
        .init(
          path: Operations.acceptShares.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: .public(.requires(.webAuth))
          ),
          body: .json(
            .init(shortGUIDs: shortGUIDs.map(Components.Schemas.ShortGUID.init(from:)))
          )
        )
      )

      let acceptData: Components.Schemas.ShortGUIDResultResponse =
        try await responseProcessor.processAcceptSharesResponse(response)
      return try (acceptData.results ?? []).map(ShareRecordInfo.init(from:))
    } catch {
      throw mapToCloudKitError(error, context: "acceptShares")
    }
  }
}
