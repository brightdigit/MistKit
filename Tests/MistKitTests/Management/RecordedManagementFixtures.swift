//
//  RecordedManagementFixtures.swift
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

/// Management API responses for unit tests, recorded from the live service.
///
/// Captured on 2026-11-24 from `https://api.icloud.apple.com` against
/// `iCloud.com.brightdigit.MistDemo` (`exportSchema`, `GET
/// /v1/database/teams/{teamId}/containers/{containerId}/environments/{environment}/schema/export`).
/// Bodies are byte-for-byte as returned, except that each `requestUuid` is
/// replaced with a placeholder. Production returned the same export as
/// development.
///
/// Live responses matched `management-openapi.yaml` (CKTool JS 1.3.2):
/// success is `200 text/plain`; every failure is `application/json`
/// `RequestError` whose `code` equals the HTTP status. `message` is a
/// kebab-case code (`invalid-or-expired-session`, `authentication-failed`,
/// `authorization-failed`), and no response included `detailedMessage` or
/// `retryAfterSeconds`.
internal enum RecordedManagementFixtures {
  // swiftlint:disable indentation_width
  /// `200 text/plain`: the development schema export.
  internal static let exportedSchemaText = """
    DEFINE SCHEMA

        RECORD TYPE Note (
            "___createTime" TIMESTAMP SORTABLE,
            "___createdBy"  REFERENCE,
            "___etag"       STRING,
            "___modTime"    TIMESTAMP SORTABLE,
            "___modifiedBy" REFERENCE,
            "___recordID"   REFERENCE QUERYABLE,
            createdAt       TIMESTAMP QUERYABLE SORTABLE,
            image           ASSET,
            index           INT64 QUERYABLE SORTABLE,
            modified        INT64 QUERYABLE,
            secret          ENCRYPTED STRING,
            tags            LIST<STRING>,
            timestamp       TIMESTAMP,
            title           STRING QUERYABLE SEARCHABLE SORTABLE,
            GRANT READ, CREATE, WRITE TO "_creator",
            GRANT READ, CREATE, WRITE TO "_icloud",
            GRANT READ TO "_world"
        );

        RECORD TYPE Users (
            "___createTime" TIMESTAMP,
            "___createdBy"  REFERENCE,
            "___etag"       STRING,
            "___modTime"    TIMESTAMP,
            "___modifiedBy" REFERENCE,
            "___recordID"   REFERENCE,
            roles           LIST<INT64>,
            GRANT WRITE TO "_creator",
            GRANT READ TO "_world"
        );

        RECORD TYPE "cloudkit.share" (
            "___createTime"               TIMESTAMP,
            "___createdBy"                REFERENCE,
            "___etag"                     STRING,
            "___modTime"                  TIMESTAMP,
            "___modifiedBy"               REFERENCE,
            "___recordID"                 REFERENCE,
            "cloudkit.thumbnailImageData" BYTES,
            "cloudkit.title"              STRING,
            "cloudkit.type"               STRING,
            GRANT WRITE TO "_creator",
            GRANT CREATE TO "_icloud",
            GRANT READ TO "_world"
        );

    """
  // swiftlint:enable indentation_width

  /// `401`: a management token that isn't valid.
  internal static let invalidTokenErrorJSON =
    #"{"code":401,"#
    + #""message":"invalid-or-expired-session","#
    + #""reason":"Failed to validate management token","#
    + #""requestUuid":"00000000-0000-4000-8000-000000000001"}"#

  /// `401`: no management token header.
  internal static let missingTokenErrorJSON =
    #"{"code":401,"#
    + #""message":"authentication-failed","#
    + #""reason":"There was a problem with your request.","#
    + #""requestUuid":"00000000-0000-4000-8000-000000000002"}"#

  /// `403`: a container that doesn't exist or the token's user can't access.
  internal static let unknownContainerErrorJSON =
    #"{"code":403,"#
    + #""message":"authorization-failed","#
    + #""reason":"User doesn't have access to container or container does not exist","#
    + #""requestUuid":"00000000-0000-4000-8000-000000000003"}"#

  /// `400`: a lower-case environment path segment (`development`).
  internal static let badRequestErrorJSON =
    #"{"code":400,"#
    + #""message":"Request unparseable or not as per supported schema","#
    + #""reason":"There was a problem with your request.","#
    + #""requestUuid":"00000000-0000-4000-8000-000000000004"}"#

  /// **Hand-written, not recorded:** a `RequestError` with every key CKTool
  /// JS 1.3.2 declares, including `detailedMessage` and `retryAfterSeconds`,
  /// which no live response has carried yet. The values are invented.
  internal static let fullRequestErrorJSON = """
    {
      "code": 503,
      "message": "service-unavailable",
      "reason": "Try again later",
      "detailedMessage": "The service is temporarily unavailable",
      "requestUuid": "00000000-0000-4000-8000-000000000009",
      "retryAfterSeconds": 30
    }
    """

  internal static func textResponse(_ text: String, statusCode: Int = 200) -> ResponseConfig {
    var headers = HTTPFields()
    headers[.contentType] = "text/plain"
    return ResponseConfig(statusCode: statusCode, headers: headers, body: Data(text.utf8))
  }

  internal static func jsonResponse(_ json: String, statusCode: Int) -> ResponseConfig {
    var headers = HTTPFields()
    headers[.contentType] = "application/json"
    return ResponseConfig(statusCode: statusCode, headers: headers, body: Data(json.utf8))
  }
}
