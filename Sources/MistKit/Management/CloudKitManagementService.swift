//
//  CloudKitManagementService.swift
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

public import Foundation
internal import OpenAPIRuntime

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

/// Service for the CloudKit Management API: the API behind `cktool` and
/// CKTool JS, used for schema operations.
///
/// The Management API is a separate service from CloudKit Web Services: it
/// lives at `https://api.icloud.apple.com` (not `api.apple-cloudkit.com`),
/// authenticates with a ``ManagementToken`` sent in the
/// `X-Apple-CloudKit-Management-Token` header (no request signing), addresses
/// containers by team, and reports errors as a JSON `RequestError`
/// (``ManagementRequestFailure``) rather than a `serverErrorCode` body.
///
/// The request format comes from Apple's CKTool JS 1.3.2
/// (`@apple/cktool.api.database`, `@apple/cktool.core`).
public struct CloudKitManagementService: Sendable {
  // swift-format-ignore: NeverForceUnwrap
  // swiftlint:disable force_unwrapping
  /// The base URL of the CloudKit Management API (CKTool JS's default
  /// `serverUrl`).
  public static let baseURL = URL(string: "https://api.icloud.apple.com")!
  // swiftlint:enable force_unwrapping

  /// The Apple Developer team that owns the container.
  public let teamIdentifier: String
  /// The CloudKit container identifier, such as `iCloud.com.example.App`.
  public let containerIdentifier: String

  internal let managementToken: ManagementToken
  internal let transport: any ClientTransport
}

#if !os(WASI)
  internal import OpenAPIURLSession

  extension CloudKitManagementService {
    /// Creates a service using the default `URLSessionTransport`.
    ///
    /// - Parameters:
    ///   - teamIdentifier: The team ID from the Membership tab of the Apple
    ///     Developer site.
    ///   - containerIdentifier: The container to manage.
    ///   - managementToken: A token from CloudKit Console's Settings.
    public init(
      teamIdentifier: String,
      containerIdentifier: String,
      managementToken: ManagementToken
    ) {
      self.init(
        teamIdentifier: teamIdentifier,
        containerIdentifier: containerIdentifier,
        managementToken: managementToken,
        transport: URLSessionTransport()
      )
    }
  }
#endif
