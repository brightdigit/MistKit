//
//  CloudKitService+WebBackend+Reads.swift
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

// Read-side `WebBackend` conformance for records and zones: lookup, changes,
// and zone listing. The primary conformance declaration lives in
// `CloudKitService+WebBackend.swift`.
extension CloudKitService {
  internal func webLookupRecords(
    recordNames: [String],
    database: MistKit.Database
  ) async throws -> [RecordInfo] {
    let results = try await lookupRecords(
      recordNames: recordNames,
      desiredKeys: nil,
      database: database
    )
    // All-or-nothing: `lookupRecords` returns a per-record `[RecordResult]`,
    // but the demo collapses it — any single failure (e.g. CloudKit's
    // NOT_FOUND) throws, so the web panel shows the error rather than
    // silently returning fewer rows than were asked for. Surfacing partial
    // results (found records alongside per-record failures) is a possible
    // future enhancement.
    return try results.map { try $0.get() }
  }

  internal func webRecordChanges(
    zoneName: String?,
    syncToken: String?,
    database: MistKit.Database
  ) async throws -> RecordChangesResult {
    try await fetchRecordChanges(
      zoneID: zoneName.map { ZoneID(zoneName: $0) },
      syncToken: syncToken,
      database: database
    )
  }

  internal func webListZones(
    database: MistKit.Database
  ) async throws -> [ZoneInfo] {
    try await listZones(database: database)
  }

  internal func webLookupZones(
    zoneNames: [String],
    database: MistKit.Database
  ) async throws -> [ZoneInfo] {
    try await lookupZones(
      zoneIDs: zoneNames.map { ZoneID(zoneName: $0) },
      database: database
    )
  }

  internal func webZoneChanges(
    syncToken: String?,
    database: MistKit.Database
  ) async throws -> ZoneChangesResult {
    try await fetchZoneChanges(syncToken: syncToken, database: database)
  }
}
