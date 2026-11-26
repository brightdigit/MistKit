//
//  InferredSchemaSource.swift
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

/// A schema inferred from the first page of a query on each named record type
/// (``InferredSchema``), for when there's neither a management token nor a
/// `.ckdb` file.
///
/// Query results carry no index options or grants, so neither does the
/// schema. It never asks for a reload.
public struct InferredSchemaSource: SchemaSource {
  /// The service the queries are sent through.
  public let service: CloudKitService
  /// The database queried.
  public let database: Database
  /// The record types queried, in order.
  public let recordTypes: [String]
  /// The zone queried; `nil` for the database's default zone.
  public let zoneID: ZoneID?
  /// The most records read per record type.
  public let limit: Int

  /// Creates a source that queries each record type.
  ///
  /// - Parameters:
  ///   - service: The service to query through.
  ///   - database: The database to query.
  ///   - recordTypes: The record types to infer; a name given twice is
  ///     queried once.
  ///   - zoneID: The zone to query; `nil` (the default) for the default zone.
  ///   - limit: The most records to read per record type. Defaults to
  ///     ``CloudKitService/maxRecordsPerRequest``, one full page.
  public init(
    service: CloudKitService,
    database: Database,
    recordTypes: [String],
    zoneID: ZoneID? = nil,
    limit: Int = CloudKitService.maxRecordsPerRequest
  ) {
    self.service = service
    self.database = database
    self.recordTypes = recordTypes
    self.zoneID = zoneID
    self.limit = limit
  }

  /// Queries one page per record type and infers the schema, with the guesses
  /// it made.
  ///
  /// - Throws: ``SchemaSourceError/noRecordTypes`` when ``recordTypes`` is
  ///   empty, and ``CloudKitError`` when a query fails.
  public func loadInferredSchema() async throws -> InferredSchema {
    guard !recordTypes.isEmpty else {
      throw SchemaSourceError.noRecordTypes
    }
    var records: [RecordInfo] = []
    var queried: Set<String> = []
    for name in recordTypes where queried.insert(name).inserted {
      let result = try await service.queryRecords(
        Query(recordType: name),
        limit: limit,
        zoneID: zoneID,
        database: database
      )
      records += result.records
    }
    return InferredSchema(inferringFrom: records, recordTypes: recordTypes)
  }

  /// Queries one page per record type and infers the schema.
  ///
  /// - Throws: What ``loadInferredSchema()`` throws.
  public func loadSchema() async throws -> CloudKitSchema {
    try await loadInferredSchema().schema
  }
}
