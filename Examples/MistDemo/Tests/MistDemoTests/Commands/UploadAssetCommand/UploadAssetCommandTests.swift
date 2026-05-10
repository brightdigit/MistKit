//
//  UploadAssetCommandTests.swift
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

@Suite("UploadAssetCommand")
internal struct UploadAssetCommandTests {
  @Test("Static command identity")
  internal func staticIdentity() {
    #expect(UploadAssetCommand.commandName == "upload-asset")
    #expect(UploadAssetCommand.abstract == "Upload binary assets to CloudKit")
    #expect(UploadAssetCommand.helpText.contains("UPLOAD-ASSET"))
    #expect(UploadAssetCommand.helpText.contains("--file"))
    #expect(UploadAssetCommand.helpText.contains("Maximum file size"))
  }

  @Test("Initializes with a configuration without throwing")
  internal func initializesWithConfig() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = UploadAssetConfig(
      base: baseConfig,
      file: "/tmp/asset.png",
      recordType: "Photo",
      fieldName: "image"
    )

    let command = UploadAssetCommand(config: config)
    // Smoke test: type-check that the value is constructable.
    _ = command
  }

  @Test("execute() throws fileNotFound for a missing file")
  internal func executeThrowsFileNotFound() async throws {
    let baseConfig = try await MistDemoConfig()
    let missingPath = "/tmp/mistdemo-missing-\(UUID().uuidString).bin"
    let config = UploadAssetConfig(
      base: baseConfig,
      file: missingPath,
      recordType: "Photo",
      fieldName: "image"
    )
    let command = UploadAssetCommand(config: config)

    await #expect(throws: UploadAssetError.self) {
      try await command.execute()
    }
  }
}
