//
//  MockBackend+RecordOperations.swift
//  MistDemoTests
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

#if canImport(Hummingbird)
  internal import MistKit

  @testable import MistDemoKit

  extension MockBackend {
    internal func webQuery(
      recordType: String,
      limit: Int?,
      sortBy: [WebRequests.QuerySortField]?,
      database: MistKit.Database
    ) async throws -> [RecordInfo] {
      lastQuery = QueryCall(
        recordType: recordType,
        limit: limit,
        sortBy: sortBy,
        database: database
      )
      try consumePendingError()
      return [
        Self.stubRecord(recordType: recordType, recordName: "stub-1")
      ]
    }

    internal func webCreate(
      recordType: String,
      recordName: String?,
      fields: [String: FieldValue],
      database: MistKit.Database
    ) async throws -> RecordInfo {
      lastCreate = CreateCall(
        recordType: recordType,
        recordName: recordName,
        fields: Self.flatten(fields),
        database: database
      )
      try consumePendingError()
      return Self.stubRecord(
        recordType: recordType, recordName: recordName ?? "created-1"
      )
    }

    internal func webUpdate(
      recordType: String,
      recordName: String,
      fields: [String: FieldValue],
      recordChangeTag: String?,
      database: MistKit.Database
    ) async throws -> RecordInfo {
      lastUpdate = UpdateCall(
        recordType: recordType,
        recordName: recordName,
        fields: Self.flatten(fields),
        recordChangeTag: recordChangeTag,
        database: database
      )
      try consumePendingError()
      return Self.stubRecord(
        recordType: recordType, recordName: recordName
      )
    }

    internal func webDelete(
      recordType: String,
      recordName: String,
      recordChangeTag: String?,
      database: MistKit.Database
    ) async throws {
      lastDelete = DeleteCall(
        recordType: recordType,
        recordName: recordName,
        recordChangeTag: recordChangeTag,
        database: database
      )
      try consumePendingError()
    }

    internal func webModifyZones(
      create: [String],
      delete: [String],
      database: MistKit.Database
    ) async throws -> [ZoneInfo] {
      lastModifyZones = ModifyZonesCall(
        create: create,
        delete: delete,
        database: database
      )
      try consumePendingError()
      return create.map { name in
        ZoneInfo(zoneName: name, ownerRecordName: nil, capabilities: [])
      }
    }
  }
#endif
