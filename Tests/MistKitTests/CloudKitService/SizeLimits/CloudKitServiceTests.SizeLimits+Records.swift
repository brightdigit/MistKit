//
//  CloudKitServiceTests.SizeLimits+Records.swift
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
import Testing

@testable import MistKit

extension CloudKitServiceTests.SizeLimits {
  @Suite("Records")
  internal struct Records {
    private static func makeService(
      statusCode: Int = 413,
      serverErrorCode: String = "QUOTA_EXCEEDED",
      reason: String = "Record exceeds maximum size"
    ) throws -> CloudKitService {
      let provider = ResponseProvider(
        defaultResponse: .cloudKitError(
          statusCode: statusCode,
          serverErrorCode: serverErrorCode,
          reason: reason
        )
      )
      return try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
        transport: MockTransport(responseProvider: provider)
      )
    }

    @Test("modifyRecords enriches QUOTA_EXCEEDED with recordExceedsSizeLimit hint")
    internal func recordHintAttachedOnOversizedBatch() async throws {
      let service = try Self.makeService()

      // 1.5 MB of string content — easily exceeds CloudKit's 1 MB per-record cap.
      let oversized = String(repeating: "x", count: 1_500_000)
      let smallOperation = RecordOperation.create(
        recordType: "Note",
        fields: ["body": .string("small")]
      )
      let oversizedOperation = RecordOperation.create(
        recordType: "Note",
        fields: ["body": .string(oversized)]
      )

      await #expect {
        _ = try await service.modifyRecords(
          [smallOperation, oversizedOperation],
          database: .public(.prefers(.serverToServer))
        )
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .quotaExceeded(_, let hint) = ckError,
          case .recordExceedsSizeLimit(let index, let bytes, let max) = hint
        else { return false }
        return index == 1
          && bytes > CloudKitService.maxRecordDataBytes
          && max == CloudKitService.maxRecordDataBytes
      }
    }

    @Test("modifyRecords passes QUOTA_EXCEEDED through unenriched when no record is oversized")
    internal func recordHintNilWhenAllRecordsSmall() async throws {
      let service = try Self.makeService(reason: "iCloud storage quota exhausted")
      let operation = RecordOperation.create(
        recordType: "Note",
        fields: ["body": .string("small")]
      )

      await #expect {
        _ = try await service.modifyRecords(
          [operation],
          database: .public(.prefers(.serverToServer))
        )
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .quotaExceeded(let reason, let hint) = ckError
        else { return false }
        return hint == nil && reason?.contains("storage quota") == true
      }
    }
  }
}
