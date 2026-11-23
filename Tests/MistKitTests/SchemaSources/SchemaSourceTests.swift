//
//  SchemaSourceTests.swift
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
internal import Testing

@testable import MistKit

@Suite("Schema sources")
internal enum SchemaSourceTests {
  /// A stream of file-change notifications and the continuation that sends
  /// them (`AsyncStream.makeStream` needs macOS 14).
  internal static func notifications() throws -> (
    AsyncStream<Void>, AsyncStream<Void>.Continuation
  ) {
    var made: AsyncStream<Void>.Continuation?
    let stream = AsyncStream<Void> { made = $0 }
    return (stream, try #require(made))
  }

  /// A `CloudKitService` whose `queryRecords` answers come from `provider`.
  internal static func service(_ provider: ResponseProvider) throws -> CloudKitService {
    try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
      transport: MockTransport(responseProvider: provider)
    )
  }

  /// A `200` `records/query` response with `json` as its body.
  internal static func queryResponse(_ json: String) -> ResponseConfig {
    .success(body: Data(json.utf8))
  }
}
