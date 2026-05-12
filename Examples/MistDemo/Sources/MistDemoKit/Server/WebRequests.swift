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
/// `fields` decodes directly into MistKit's `FieldValue`, which has a custom
/// Codable that accepts raw JSON primitives (string → `.string`, integer →
/// `.int64`, floating-point → `.double`) along with the complex CloudKit
/// shapes (location, reference, asset, list). So the browser can send the
/// natural `{"title":"Hi","index":5}` shape without a custom request type.
internal enum WebRequests {
  /// One sort descriptor: a field name plus a direction. Field names follow
  /// CloudKit Web Services / CloudKit JS naming — including the implicit
  /// system fields `___createTime` and `___modTime`, which must be marked
  /// SORTABLE in the schema.
  internal struct QuerySortField: Decodable, Sendable {
    /// CloudKit Web Services field name. Note: CloudKit JS's
    /// `performQuery({ sortBy })` uses `fieldName` for the same concept —
    /// the browser-side code maps this property to `fieldName` when issuing
    /// CloudKit-JS-mode queries (see `queryNotes` in `index.html`).
    internal let field: String
    internal let ascending: Bool
  }

  /// `POST /api/records/query`
  internal struct Query: Decodable {
    internal let recordType: String
    internal let limit: Int?
    internal let sortBy: [QuerySortField]?
  }

  /// `POST /api/records/create`
  internal struct Create: Decodable {
    internal let recordType: String
    internal let fields: [String: FieldValue]
  }

  /// `POST /api/records/update`
  ///
  /// `recordChangeTag` carries the optimistic-locking token CloudKit returns
  /// on every record. The browser already holds it from the last query, so
  /// it forwards directly to MistKit without a server-side fetch round-trip.
  internal struct Update: Decodable {
    internal let recordType: String
    internal let recordName: String
    internal let fields: [String: FieldValue]
    internal let recordChangeTag: String?
  }

  /// `POST /api/records/delete`
  ///
  /// `recordChangeTag` is required by CloudKit Web Services to delete an
  /// existing record. Omitting it produces `BadRequestException: missing
  /// required field 'recordChangeTag'`.
  internal struct Delete: Decodable {
    internal let recordType: String
    internal let recordName: String
    internal let recordChangeTag: String?
  }
}
