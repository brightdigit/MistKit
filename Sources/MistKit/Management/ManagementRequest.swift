//
//  ManagementRequest.swift
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
internal import HTTPTypes

/// One CloudKit Management API request, before authentication is attached.
internal struct ManagementRequest: Sendable, Equatable {
  /// RFC 3986 unreserved characters. CKTool JS escapes path parameters with
  /// `encodeURIComponent`; this set agrees with it for identifiers CloudKit
  /// accepts.
  private static let pathSegmentAllowed = CharacterSet(
    charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
  )

  internal let operationID: String
  internal let method: HTTPRequest.Method
  /// The path after the base URL, already percent-encoded.
  internal let path: String
  internal let accept: String

  /// CKTool JS `exportSchema`.
  internal static func exportSchema(
    teamIdentifier: String,
    containerIdentifier: String,
    environment: Environment
  ) -> ManagementRequest {
    let path =
      "/v1/database/teams/\(encode(teamIdentifier))"
      + "/containers/\(encode(containerIdentifier))"
      + "/environments/\(encode(environment.managementPathValue))/schema/export"
    return ManagementRequest(
      operationID: "exportSchema",
      method: .get,
      path: path,
      accept: "text/plain"
    )
  }

  private static func encode(_ segment: String) -> String {
    segment.addingPercentEncoding(withAllowedCharacters: pathSegmentAllowed) ?? segment
  }

  /// The request with the `X-Apple-CloudKit-Management-Token` header.
  internal func httpRequest(managementToken: ManagementToken) -> HTTPRequest {
    var headerFields = HTTPFields()
    headerFields[.cloudKitManagementToken] = managementToken.value
    headerFields[.accept] = accept
    return HTTPRequest(
      method: method,
      scheme: nil,
      authority: nil,
      path: path,
      headerFields: headerFields
    )
  }
}

extension Environment {
  /// The Management API spells environments in upper case (CKTool JS
  /// `CKEnvironment`: `DEVELOPMENT`, `PRODUCTION`).
  internal var managementPathValue: String {
    switch self {
    case .development: "DEVELOPMENT"
    case .production: "PRODUCTION"
    }
  }
}
