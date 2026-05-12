//
//  WebDemoRequests.swift
//  MistDemo
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
internal import MistKit

/// Request/response payloads for the web-demo's CRUD endpoints.
///
/// Field values are limited to string in the request body so the HTML form
/// schema stays trivial. Wider FieldValue coverage (numbers, dates, refs)
/// can land later once the demo UI exposes typed input controls.
internal enum WebDemoRequests {
  /// `POST /api/records/query`
  internal struct QueryRequest: Decodable {
    internal let recordType: String
    internal let limit: Int?
  }

  /// `POST /api/records/create`
  internal struct CreateRequest: Decodable {
    internal let recordType: String
    internal let fields: [String: String]
  }

  /// `POST /api/records/update`
  internal struct UpdateRequest: Decodable {
    internal let recordType: String
    internal let recordName: String
    internal let fields: [String: String]
  }

  /// `POST /api/records/delete`
  internal struct DeleteRequest: Decodable {
    internal let recordType: String
    internal let recordName: String
  }

  /// Body returned by record-shaped routes (query / create / update).
  internal struct RecordsResponse: Encodable {
    internal let records: [RecordInfo]
  }

  /// Body returned by `delete` (no record payload).
  internal struct DeleteResponse: Encodable {
    internal let recordName: String
    internal let deleted: Bool
  }

  /// Body returned for any handled CloudKit/MistKit error so the UI can
  /// surface the message without parsing transport-level failures.
  internal struct ErrorResponse: Encodable {
    internal let message: String
  }

  /// Convert a JSON `[String: String]` request payload into the
  /// `FieldValue` map MistKit expects.
  internal static func stringFields(
    _ raw: [String: String]
  ) -> [String: FieldValue] {
    var result: [String: FieldValue] = [:]
    for (name, value) in raw {
      result[name] = .string(value)
    }
    return result
  }
}
