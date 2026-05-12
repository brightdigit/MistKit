//
//  WebRequests.swift
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

/// Request payloads for the web command's CRUD endpoints.
///
/// Field values are limited to string in the request body so the HTML form
/// schema stays trivial. Wider FieldValue coverage (numbers, dates, refs)
/// can land later once the demo UI exposes typed input controls.
internal enum WebRequests {
  /// `POST /api/records/query`
  internal struct Query: Decodable {
    internal let recordType: String
    internal let limit: Int?
  }

  /// `POST /api/records/create`
  internal struct Create: Decodable {
    internal let recordType: String
    internal let fields: [String: String]
  }

  /// `POST /api/records/update`
  internal struct Update: Decodable {
    internal let recordType: String
    internal let recordName: String
    internal let fields: [String: String]
  }

  /// `POST /api/records/delete`
  internal struct Delete: Decodable {
    internal let recordType: String
    internal let recordName: String
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
