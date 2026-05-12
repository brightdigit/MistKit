//
//  WebDemoBackend.swift
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

/// Narrow abstraction over the MistKit `CloudKitService` methods the web
/// demo's CRUD routes call. Lets the routes be tested without a live
/// CloudKit container — tests supply a mock conformer.
///
/// The production implementation is `CloudKitService` itself via
/// extension; the web demo builds a new service per request using the
/// captured `ckWebAuthToken`.
internal protocol WebDemoBackend: Sendable {
  func webDemoQuery(
    recordType: String,
    limit: Int?
  ) async throws -> [RecordInfo]

  func webDemoCreate(
    recordType: String,
    fields: [String: FieldValue]
  ) async throws -> RecordInfo

  func webDemoUpdate(
    recordType: String,
    recordName: String,
    fields: [String: FieldValue]
  ) async throws -> RecordInfo

  func webDemoDelete(
    recordType: String,
    recordName: String
  ) async throws
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService: WebDemoBackend {
  internal func webDemoQuery(
    recordType: String,
    limit: Int?
  ) async throws -> [RecordInfo] {
    let result = try await queryRecords(
      recordType: recordType,
      filters: nil,
      sortBy: nil,
      limit: limit,
      desiredKeys: nil,
      continuationMarker: nil,
      database: .private
    )
    return result.records
  }

  internal func webDemoCreate(
    recordType: String,
    fields: [String: FieldValue]
  ) async throws -> RecordInfo {
    try await createRecord(
      recordType: recordType,
      fields: fields,
      database: .private
    )
  }

  internal func webDemoUpdate(
    recordType: String,
    recordName: String,
    fields: [String: FieldValue]
  ) async throws -> RecordInfo {
    try await updateRecord(
      recordType: recordType,
      recordName: recordName,
      fields: fields,
      database: .private
    )
  }

  internal func webDemoDelete(
    recordType: String,
    recordName: String
  ) async throws {
    try await deleteRecord(
      recordType: recordType,
      recordName: recordName,
      database: .private
    )
  }
}

/// Factory that returns a `WebDemoBackend` configured with the captured
/// web-auth token. Injected into `WebDemoServer` so tests can supply a
/// mock without going through MistKit.
internal struct WebDemoBackendFactory: Sendable {
  internal let make: @Sendable (_ webAuthToken: String) throws -> any WebDemoBackend

  internal init(
    make: @escaping @Sendable (_ webAuthToken: String) throws -> any WebDemoBackend
  ) {
    self.make = make
  }

  /// Production factory: builds a `CloudKitService` for the private
  /// database with the captured web-auth token paired with the
  /// command's API token.
  internal static func live(
    apiToken: String,
    containerIdentifier: String,
    environment: MistKit.Environment
  ) -> WebDemoBackendFactory {
    WebDemoBackendFactory { webAuthToken in
      let tokenManager = WebAuthTokenManager(
        apiToken: apiToken,
        webAuthToken: webAuthToken
      )
      return CloudKitService(
        containerIdentifier: containerIdentifier,
        tokenManager: tokenManager,
        environment: environment
      )
    }
  }
}
