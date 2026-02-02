//
//  CloudKitServiceUploadTests+ErrorHandling.swift
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

extension CloudKitServiceUploadTests {
  @Suite("Error Handling")
  internal struct ErrorHandling {
    @Test("uploadAssets() handles unauthorized error (401)")
    internal func uploadAssetsHandlesUnauthorizedError() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceUploadTests.makeAuthErrorService()
      let testData = Data(count: 1024)

      do {
        _ = try await service.uploadAssets(
          data: testData,
          recordType: "Note",
          fieldName: "image"
        )
        Issue.record("Expected authentication error")
      } catch let error as CloudKitError {
        if case .httpErrorWithRawResponse(let statusCode, let response) = error {
          #expect(statusCode == 401, "Should return 401 Unauthorized")
          #expect(response.contains("AUTHENTICATION_FAILED") || response.contains("Authentication failed"))
        } else {
          Issue.record("Expected httpErrorWithRawResponse error, got \(error)")
        }
      } catch {
        Issue.record("Expected CloudKitError, got \(type(of: error))")
      }
    }

    @Test("uploadAssets() handles bad request error (400)")
    internal func uploadAssetsHandlesBadRequestError() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceUploadTests.makeUploadValidationErrorService(.emptyData)
      let testData = Data()  // Empty data triggers 400

      do {
        _ = try await service.uploadAssets(
          data: testData,
          recordType: "Note",
          fieldName: "image"
        )
        Issue.record("Expected bad request error")
      } catch let error as CloudKitError {
        if case .httpErrorWithRawResponse(let statusCode, _) = error {
          #expect(statusCode == 400, "Should return 400 Bad Request")
        } else {
          Issue.record("Expected httpErrorWithRawResponse error, got \(error)")
        }
      } catch {
        Issue.record("Expected CloudKitError, got \(type(of: error))")
      }
    }
  }
}
