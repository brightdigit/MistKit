//
//  CloudKitService+LookupOperations.swift
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
internal import MistKitOpenAPI

extension CloudKitService {
  /// Lookup records by record names
  /// - Parameters:
  ///   - recordNames: Record names to fetch
  ///   - desiredKeys: Optional array of field names to fetch
  ///   - database: The CloudKit database scope to read from (`.public`, `.private`, `.shared`)
  /// - Returns: Array of RecordInfo for the matched records
  /// - Throws: CloudKitError if the operation fails
  ///
  /// # Example: Bulk lookup with field projection
  /// ```swift
  /// let articles = try await service.lookupRecords(
  ///   recordNames: ["article-001", "article-002", "article-003"],
  ///   desiredKeys: ["title", "publishedDate"],
  ///   database: .private
  /// )
  /// ```
  ///
  /// - Note: Pass `desiredKeys` to limit which fields come back. Useful
  ///   for list views that only need a projection.
  /// - Note: This is the single-request primitive — CloudKit caps it at
  ///   ``maxRecordsPerRequest`` record names. For larger inputs use
  ///   ``lookupAllRecords(recordNames:desiredKeys:database:batchSize:)``, which
  ///   chunks automatically.
  /// - Returns: A ``RecordResult`` per requested record — `.success` for a found
  ///   record, `.failure` (e.g. `NOT_FOUND`) for one CloudKit could not return.
  public func lookupRecords(
    recordNames: [String],
    desiredKeys: [String]? = nil,
    database: Database
  ) async throws(CloudKitError) -> [RecordResult] {
    do {
      let client = try self.client(for: database)
      let response = try await client.lookupRecords(
        .init(
          path: Operations.lookupRecords.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
          ),
          body: .json(
            .init(
              records: recordNames.map { recordName in
                .init(
                  recordName: recordName,
                  desiredKeys: desiredKeys
                )
              }
            )
          )
        )
      )

      let lookupData: Components.Schemas.LookupResponse =
        try await responseProcessor.processLookupRecordsResponse(response)
      return try (lookupData.records ?? []).map { try RecordResult(from: $0) }
    } catch {
      throw mapToCloudKitError(error, context: "lookupRecords")
    }
  }
}
