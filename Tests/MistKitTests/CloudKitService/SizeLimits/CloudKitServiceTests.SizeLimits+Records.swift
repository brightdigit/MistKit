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
    private static func makeService() throws -> CloudKitService {
      let transport = MockTransport(responseProvider: ResponseProvider(defaultResponse: .success()))
      return try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
        transport: transport
      )
    }

    @Test("createRecord rejects record exceeding 1 MB field-data limit")
    internal func createRecordRejectsOversizedFields() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Self.makeService()

      // 1.5 MB of string content — easily exceeds CloudKit's 1 MB per-record cap.
      let oversizedString = String(repeating: "x", count: 1_500_000)
      let fields: [String: FieldValue] = ["body": .string(oversizedString)]

      do {
        _ = try await service.createRecord(
          recordType: "Note",
          fields: fields,
          database: .public(.prefers(.serverToServer))
        )
        Issue.record("Expected invalidArgument for oversized record")
      } catch {
        guard case .invalidArgument(let parameter, let reason) = error else {
          Issue.record("Expected invalidArgument, got \(error)")
          return
        }
        #expect(parameter.contains("record"))
        #expect(reason.contains("1 MB"))
      }
    }

    @Test("modifyRecords surfaces the offending operation index")
    internal func modifyRecordsSurfacesOffendingIndex() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Self.makeService()

      let okOperation = RecordOperation.create(
        recordType: "Note",
        recordName: nil,
        fields: ["body": .string("ok")]
      )
      let oversizedOperation = RecordOperation.create(
        recordType: "Note",
        recordName: nil,
        fields: ["body": .string(String(repeating: "x", count: 1_500_000))]
      )

      do {
        _ = try await service.modifyRecords(
          [okOperation, oversizedOperation],
          database: .public(.prefers(.serverToServer))
        )
        Issue.record("Expected invalidArgument for oversized record")
      } catch {
        guard case .invalidArgument(let parameter, _) = error else {
          Issue.record("Expected invalidArgument, got \(error)")
          return
        }
        #expect(parameter == "operations[1].record")
      }
    }

    @Test("createRecord accepts small records (does not validate-throw)")
    internal func createRecordAcceptsSmallRecord() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Self.makeService()

      let fields: [String: FieldValue] = ["body": .string("hello")]

      do {
        _ = try await service.createRecord(
          recordType: "Note",
          fields: fields,
          database: .public(.prefers(.serverToServer))
        )
        Issue.record("Expected network error — no real transport configured")
      } catch {
        if case .invalidArgument = error {
          Issue.record("Validation should not fail for small record: \(error)")
        }
        // Other errors (auth, network, decoding) are expected.
      }
    }
  }
}
