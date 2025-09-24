//
//  CloudKitService+Operations.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Fetch current user information
  public func fetchCurrentUser() async throws -> UserInfo {
    let response = try await client.getCurrentUser(
      .init(
        path: createGetCurrentUserPath(containerIdentifier: containerIdentifier)
      )
    )

    let userData: Components.Schemas.UserResponse =
      try await responseProcessor.processGetCurrentUserResponse(response)
    return UserInfo(from: userData)
  }

  /// List zones in the user's private database
  public func listZones() async throws -> [ZoneInfo] {
    let response = try await client.listZones(
      .init(
        path: createListZonesPath(containerIdentifier: containerIdentifier)
      )
    )

    let zonesData: Components.Schemas.ZonesListResponse =
      try await responseProcessor.processListZonesResponse(response)
    return zonesData.zones?.compactMap { zone in
      guard let zoneID = zone.zoneID else {
        return nil
      }
      return ZoneInfo(
        zoneName: zoneID.zoneName ?? "Unknown",
        ownerRecordName: zoneID.ownerName,
        capabilities: []
      )
    } ?? []
  }

  /// Query records from the default zone
  public func queryRecords(recordType: String, limit: Int = 10) async throws -> [RecordInfo] {
    let response = try await client.queryRecords(
      .init(
        path: createQueryRecordsPath(containerIdentifier: containerIdentifier),
        body: .json(
          .init(
            zoneID: .init(zoneName: "_defaultZone"),
            resultsLimit: limit,
            query: .init(
              recordType: recordType,
              sortBy: [
                //                            .init(
                //                                fieldName: "modificationDate",
                //                                ascending: false
                //                            )
              ]
            )
          )
        )
      )
    )

    let recordsData: Components.Schemas.QueryResponse =
      try await responseProcessor.processQueryRecordsResponse(response)
    return recordsData.records?.compactMap { RecordInfo(from: $0) } ?? []
  }
}
