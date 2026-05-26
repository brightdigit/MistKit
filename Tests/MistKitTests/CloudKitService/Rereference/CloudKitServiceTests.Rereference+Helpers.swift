//
//  CloudKitServiceTests.Rereference+Helpers.swift
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
  internal enum Rereference {}
}

extension CloudKitServiceTests.Rereference {
  internal static let publicDatabase: Database = .public(.prefers(.serverToServer))

  /// Build a service whose mock transport answers each operation by ID. Any
  /// operation without an explicit response falls back to an empty success.
  internal static func makeService(
    responsesByOperation: [String: ResponseConfig]
  ) throws -> CloudKitService {
    let provider = ResponseProvider(
      responses: responsesByOperation,
      defaultResponse: .success(body: Data("{}".utf8))
    )
    let transport = MockTransport(responseProvider: provider)
    return try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
      transport: transport
    )
  }

  // MARK: - JSON builders

  /// A single asset descriptor dictionary (all six fields).
  internal static func assetDictionary(
    fileChecksum: String,
    downloadURL: String = "https://cvws.icloud-content.com/asset"
  ) -> [String: Any] {
    [
      "fileChecksum": fileChecksum,
      "size": 1_024,
      "referenceChecksum": "ref-\(fileChecksum)",
      "wrappingKey": "wk-\(fileChecksum)",
      "receipt": "rcpt-\(fileChecksum)",
      "downloadURL": downloadURL,
    ]
  }

  /// `assets/rereference` 200 body wrapping the given per-item entries.
  internal static func rereferenceResponse(assets: [[String: Any]]) throws -> ResponseConfig {
    try jsonResponse(["assets": assets])
  }

  /// A `records/lookup` (or modify) 200 body wrapping one record.
  internal static func recordsResponse(_ records: [[String: Any]]) throws -> ResponseConfig {
    try jsonResponse(["records": records])
  }

  /// A "Note" record dictionary, optionally carrying an asset on `image`.
  internal static func noteRecord(
    recordName: String,
    changeTag: String = "tag-1",
    imageChecksum: String? = nil
  ) -> [String: Any] {
    var fields: [String: Any] = [
      "title": ["value": "Note", "type": "STRING"]
    ]
    if let imageChecksum {
      fields["image"] = [
        "value": assetDictionary(fileChecksum: imageChecksum),
        "type": "ASSETID",
      ]
    }
    return [
      "recordName": recordName,
      "recordType": "Note",
      "recordChangeTag": changeTag,
      "fields": fields,
    ]
  }

  private static func jsonResponse(_ object: [String: Any]) throws -> ResponseConfig {
    let body = try JSONSerialization.data(withJSONObject: object)
    var headers = HTTPFields()
    headers[.contentType] = "application/json"
    return ResponseConfig(statusCode: 200, headers: headers, body: body, error: nil)
  }
}
