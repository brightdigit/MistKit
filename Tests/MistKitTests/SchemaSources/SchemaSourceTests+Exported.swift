//
//  SchemaSourceTests+Exported.swift
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

extension SchemaSourceTests {
  @Suite("Exported")
  internal struct Exported {
    @Test("loads the parsed Management API export and never asks for a reload")
    internal func loads() async throws {
      let (service, transport) = CloudKitManagementServiceTests.makeService(
        response: ProvisionalManagementFixtures.textResponse(
          ProvisionalManagementFixtures.exportedSchemaText
        )
      )
      let source = ExportedSchemaSource(service: service, environment: .production)
      let schema = try await source.loadSchema()
      #expect(
        schema == (try CloudKitSchema(parsing: ProvisionalManagementFixtures.exportedSchemaText))
      )
      #expect(
        await transport.sent.first?.request.path?.hasSuffix("PRODUCTION/schema/export") == true)
      var changes = source.schemaChanges().makeAsyncIterator()
      #expect(await changes.next() == nil)
    }

    @Test("an export that isn't valid schema language throws invalidSchema")
    internal func invalid() async {
      let (service, _) = CloudKitManagementServiceTests.makeService(
        response: ProvisionalManagementFixtures.textResponse("not a schema")
      )
      await #expect {
        _ = try await ExportedSchemaSource(service: service, environment: .development)
          .loadSchema()
      } throws: { error in
        guard case .invalidSchema = error as? CloudKitManagementError else {
          return false
        }
        return true
      }
    }
  }
}
