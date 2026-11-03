//
//  ProvisionalManagementFixtures.swift
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

/// Management API responses for unit tests.
///
/// **PROVISIONAL — hand-written and unverified.** No live Management API
/// response has been recorded yet. Each fixture below is built from the
/// response contract in Apple's CKTool JS 1.3.2 (`@apple/cktool.api.database`
/// `exportSchemaOp`: `200 text/plain` schema file; any other status a JSON
/// `RequestError`). Replace them with recorded responses once a scratch
/// container is available (Mistico W0-2).
internal enum ProvisionalManagementFixtures {
  /// PROVISIONAL, hand-written and unverified: a `200` export body in
  /// CloudKit Schema Language, shaped like `cktool export-schema` output.
  internal static let exportedSchemaText = """
    DEFINE SCHEMA

      CREATE ROLE Organizer;

      RECORD TYPE Player (
        "___createTime" TIMESTAMP QUERYABLE SORTABLE,
        "___recordID"   REFERENCE QUERYABLE,
        displayName     STRING QUERYABLE SORTABLE SEARCHABLE,
        country         STRING,
        rating          INT64 QUERYABLE SORTABLE,
        avatar          ASSET,
        GRANT WRITE TO "_creator",
        GRANT CREATE TO "_icloud",
        GRANT READ TO "_world",
        GRANT READ, WRITE TO Organizer
      );

      RECORD TYPE Match (
        "___recordID"   REFERENCE QUERYABLE,
        players         LIST<REFERENCE> QUERYABLE,
        playedAt        TIMESTAMP SORTABLE,
        GRANT READ TO "_world"
      );
    """

  /// PROVISIONAL, hand-written and unverified: a JSON `RequestError` body as
  /// CKTool JS 1.3.2 declares it (`code`, `message`, `reason`,
  /// `detailedMessage`, `requestUuid`, `retryAfterSeconds`). The values are
  /// invented.
  internal static let requestErrorJSON = """
    {
      "code": 401,
      "message": "AUTHENTICATION_FAILED",
      "reason": "Management token is invalid or expired",
      "detailedMessage": "Generate a new token in CloudKit Console",
      "requestUuid": "6E1D9A6B-0000-4000-8000-000000000001",
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
