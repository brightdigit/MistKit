//
//  CloudKitServiceTests.Sharing+Helpers.swift
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
internal import Testing

@testable import MistKit

extension CloudKitServiceTests {
  internal enum Sharing {}
}

extension CloudKitServiceTests.Sharing {
  /// Build a web-auth service whose mock transport answers each operation by
  /// ID, alongside the provider so tests can inspect recorded request bodies.
  ///
  /// `records/resolve` and `records/accept` are user-context routes, so the
  /// credentials always carry a web-auth token.
  internal static func makeServiceWithProvider(
    responsesByOperation: [String: ResponseConfig]
  ) throws -> (service: CloudKitService, provider: ResponseProvider) {
    let provider = ResponseProvider(
      responses: responsesByOperation,
      defaultResponse: .success(body: Data("{}".utf8))
    )
    let transport = MockTransport(responseProvider: provider)
    let service = try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(
        apiAuth: APICredentials(
          apiToken: TestConstants.apiToken,
          webAuthToken: TestConstants.webAuthToken
        )
      ),
      transport: transport
    )
    return (service, provider)
  }

  internal static func makeService(
    responsesByOperation: [String: ResponseConfig]
  ) throws -> CloudKitService {
    try makeServiceWithProvider(responsesByOperation: responsesByOperation).service
  }

  // MARK: - JSON builders

  /// A `records/resolve` / `records/accept` 200 body wrapping the given results.
  internal static func shortGUIDResponse(results: [[String: Any]]) throws -> ResponseConfig {
    try jsonResponse(["results": results])
  }

  /// A fully-populated ShortGUID Result dictionary.
  internal static func shortGUIDResult(
    value: String,
    participantStatus: String = "ACCEPTED",
    includeRootRecord: Bool = true
  ) -> [String: Any] {
    var result: [String: Any] = [
      "shortGUID": ["value": value, "shouldFetchRootRecord": true],
      "containerIdentifier": TestConstants.serviceContainerIdentifier,
      "databaseScope": "SHARED",
      "environment": "development",
      "zoneID": ["zoneName": "SharedZone", "ownerRecordName": "_owner"],
      "rootRecordName": "root-\(value)",
      "share": shareRecord(for: value),
      "ownerIdentity": [
        "userRecordName": "_owner",
        "nameComponents": ["givenName": "Owner", "familyName": "User"],
      ],
      "participantPermission": "READ_WRITE",
      "participantStatus": participantStatus,
      "participantType": "USER",
      "webpageURL": "https://www.icloud.com/share/\(value)",
    ]
    if includeRootRecord {
      result["rootRecord"] = [
        "recordName": "root-\(value)",
        "recordType": "Note",
        "recordChangeTag": "tag-1",
        "fields": ["title": ["value": "Shared Note", "type": "STRING"]],
      ]
    }
    return result
  }

  /// A `cloudkit.share` record dictionary carrying share response keys.
  internal static func shareRecord(for value: String) -> [String: Any] {
    let owner: [String: Any] = [
      "permission": "READ_WRITE",
      "type": "OWNER",
      "acceptanceStatus": "ACCEPTED",
      "userIdentity": ["userRecordName": "_owner"],
    ]
    return [
      "recordName": "share-\(value)",
      "recordType": ShareInfo.recordType,
      "recordChangeTag": "share-tag-1",
      "fields": [:],
      "shortGUID": value,
      "publicPermission": "READ_ONLY",
      "participants": [owner],
      "owner": owner,
      "currentUserParticipant": owner,
    ]
  }

  /// A result carrying a `potentialMatchList` instead of an identified caller.
  internal static func ambiguousResult(value: String) -> [String: Any] {
    [
      "shortGUID": ["value": value],
      "participantStatus": "INVITED",
      "potentialMatchList": [
        [
          "participantId": "candidate-1",
          "contactInformation": ["emailAddress": "one@example.com"],
        ],
        [
          "participantId": "candidate-2",
          "contactInformation": ["phoneNumber": "+15550100"],
        ],
      ],
    ]
  }

  /// A `records/modify` 200 body wrapping the given records.
  internal static func recordsResponse(_ records: [[String: Any]]) throws -> ResponseConfig {
    try jsonResponse(["records": records])
  }

  /// A root record created with a short GUID for share tests.
  internal static func shareableRootRecord(
    recordName: String = "root-1",
    changeTag: String = "tag-1",
    shortGUID: String = "guid-share-1"
  ) -> [String: Any] {
    [
      "recordName": recordName,
      "recordType": "Note",
      "recordChangeTag": changeTag,
      "fields": ["title": ["value": "Shared Note", "type": "STRING"]],
      "shortGUID": shortGUID,
    ]
  }

  /// A `cloudkit.share` record response carrying share-create keys.
  internal static func createdShareRecord(
    recordName: String = "share-1",
    changeTag: String = "share-tag-1",
    shortGUID: String = "guid-share-1"
  ) -> [String: Any] {
    let owner: [String: Any] = [
      "permission": "READ_WRITE",
      "type": "OWNER",
      "acceptanceStatus": "ACCEPTED",
      "userIdentity": ["userRecordName": "_owner"],
    ]
    let invitee: [String: Any] = [
      "permission": "READ_WRITE",
      "type": "USER",
      "acceptanceStatus": "INVITED",
      "userIdentity": [
        "lookupInfo": ["emailAddress": "sharee@example.com"]
      ],
    ]
    return [
      "recordName": recordName,
      "recordType": ShareInfo.recordType,
      "recordChangeTag": changeTag,
      "fields": [:],
      "shortGUID": shortGUID,
      "share": ["recordName": recordName],
      "publicPermission": "NONE",
      "participants": [owner, invitee],
      "owner": owner,
      "currentUserParticipant": owner,
    ]
  }

  private static func jsonResponse(_ object: [String: Any]) throws -> ResponseConfig {
    let body = try JSONSerialization.data(withJSONObject: object)
    var headers = HTTPFields()
    headers[.contentType] = "application/json"
    return ResponseConfig(statusCode: 200, headers: headers, body: body, error: nil)
  }
}
