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

import Foundation

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Modify (create, update, delete) records
  @available(
    *, deprecated,
    message: "Use modifyRecords(_:) with RecordOperation in CloudKitService+WriteOperations instead"
  )
  internal func modifyRecords(
    operations: [Components.Schemas.RecordOperation],
    atomic: Bool = true,
    database: Database? = nil
  ) async throws(CloudKitError) -> [RecordInfo] {
    let effectiveDatabase = database ?? self.database
    do {
      let response = try await client.modifyRecords(
        .init(
          path: createModifyRecordsPath(
            containerIdentifier: containerIdentifier,
            database: effectiveDatabase
          ),
          body: .json(
            .init(
              operations: operations,
              atomic: atomic
            )
          )
        )
      )

      let modifyData: Components.Schemas.ModifyResponse =
        try await responseProcessor.processModifyRecordsResponse(response)
      return modifyData.records?.compactMap { RecordInfo(from: $0) } ?? []
    } catch {
      throw mapToCloudKitError(error, context: "modifyRecords")
    }
  }

  /// Lookup records by record names
  public func lookupRecords(
    recordNames: [String],
    desiredKeys: [String]? = nil,
    database: Database? = nil
  ) async throws(CloudKitError) -> [RecordInfo] {
    let effectiveDatabase = database ?? self.database
    do {
      let response = try await client.lookupRecords(
        .init(
          path: createLookupRecordsPath(
            containerIdentifier: containerIdentifier,
            database: effectiveDatabase
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
      return lookupData.records?.compactMap { RecordInfo(from: $0) } ?? []
    } catch {
      throw mapToCloudKitError(error, context: "lookupRecords")
    }
  }
}
