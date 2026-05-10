//
//  UploadAssetConfigTests.swift
//  MistDemoTests
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

@testable import MistDemoKit

@Suite("UploadAssetConfig")
internal struct UploadAssetConfigTests {
  @Test("UploadAssetConfig initializes with required file and defaults")
  internal func initializesWithRequiredFile() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = UploadAssetConfig(
      base: baseConfig,
      file: "/tmp/asset.png",
      recordType: "Photo",
      fieldName: "image"
    )

    #expect(config.file == "/tmp/asset.png")
    #expect(config.recordType == "Photo")
    #expect(config.fieldName == "image")
    #expect(config.recordName == nil)
    #expect(config.output == .json)
  }

  @Test("UploadAssetConfig keeps explicit memberwise values")
  internal func acceptsExplicitFields() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = UploadAssetConfig(
      base: baseConfig,
      file: "/tmp/asset.png",
      recordType: "Photo",
      fieldName: "thumbnail",
      recordName: "rec-9",
      output: .table
    )

    #expect(config.recordName == "rec-9")
    #expect(config.fieldName == "thumbnail")
    #expect(config.output == .table)
  }
}
