//
//  UploadAssetConfigTests+ParseFromConfiguration.swift
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

import Configuration
import Foundation
import Testing

@testable import MistDemoKit

extension UploadAssetConfigTests {
  private static func baseValues(
    filePath: String? = "/tmp/asset.png"
  ) -> [String: ConfigValue] {
    var values: [String: ConfigValue] = [
      "container.identifier": .init(stringLiteral: "iCloud.com.test.App"),
      "api.token": .init(stringLiteral: "test-api-token"),
      "environment": .init(stringLiteral: "development"),
      "database": .init(stringLiteral: "private"),
    ]
    if let filePath {
      values["file"] = .init(stringLiteral: filePath)
    }
    return values
  }

  @Test("Parses defaults when only file is provided")
  internal func parsesDefaults() async throws {
    let configuration = MistDemoConfiguration.testing(Self.baseValues())

    let config = try await UploadAssetConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.file == "/tmp/asset.png")
    #expect(config.recordType == "Note")
    #expect(config.fieldName == "image")
    #expect(config.recordName == nil)
    #expect(config.output == .json)
  }

  @Test("Throws filePathRequired when file is missing")
  internal func throwsWhenFilePathMissing() async throws {
    let configuration = MistDemoConfiguration.testing(
      Self.baseValues(filePath: nil)
    )

    await #expect(throws: UploadAssetError.self) {
      _ = try await UploadAssetConfig(
        configuration: configuration,
        base: nil
      )
    }
  }

  @Test("Reuses an explicit base config")
  internal func reusesExplicitBase() async throws {
    let configuration = MistDemoConfiguration.testing(Self.baseValues())
    let baseConfig = try await MistDemoConfig()

    let config = try await UploadAssetConfig(
      configuration: configuration,
      base: baseConfig
    )

    #expect(config.base.containerIdentifier == baseConfig.containerIdentifier)
  }
}
