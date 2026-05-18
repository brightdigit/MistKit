//
//  CloudKitServiceTests.SizeLimits+Assets.swift
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
  @Suite("Assets")
  internal struct Assets {
    private static func makeService() throws -> CloudKitService {
      let transport = MockTransport(responseProvider: ResponseProvider(defaultResponse: .success()))
      return try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
        transport: transport
      )
    }

    @Test("uploadAssetData rejects data exceeding 15 MB", .disabled(if: Platform.isWasm))
    internal func uploadAssetDataRejectsOversizedData() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Self.makeService()
      let oversizedData = Data(count: 15 * 1_024 * 1_024 + 1)
      let url = try #require(URL(string: "https://cvws.icloud-content.com/test"))

      // Uploader must never be called when validation rejects up-front.
      let uploader: AssetUploader = { _, _ in
        Issue.record("uploader must not be invoked for oversized data")
        return (200, Data())
      }

      do {
        _ = try await service.uploadAssetData(oversizedData, to: url, using: uploader)
        Issue.record("Expected invalidArgument for oversized asset data")
      } catch {
        guard case .invalidArgument(let parameter, let reason) = error else {
          Issue.record("Expected invalidArgument, got \(error)")
          return
        }
        #expect(parameter == "data")
        #expect(reason.contains("15 MB"))
      }
    }

    @Test("uploadAssetData accepts data at the 15 MB boundary", .disabled(if: Platform.isWasm))
    internal func uploadAssetDataAcceptsBoundary() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Self.makeService()
      let boundaryData = Data(count: 15 * 1_024 * 1_024)
      let url = try #require(URL(string: "https://cvws.icloud-content.com/test"))

      let uploader: AssetUploader = { _, _ in
        let response = """
          {
            "singleFile": {
              "wrappingKey": "wk",
              "fileChecksum": "fc",
              "receipt": "r",
              "referenceChecksum": "rc",
              "size": \(15 * 1_024 * 1_024)
            }
          }
          """
        return (200, Data(response.utf8))
      }

      _ = try await service.uploadAssetData(boundaryData, to: url, using: uploader)
    }
  }
}
