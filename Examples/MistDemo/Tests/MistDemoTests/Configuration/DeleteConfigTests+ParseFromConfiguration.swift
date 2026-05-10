//
//  DeleteConfigTests+ParseFromConfiguration.swift
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

extension DeleteConfigTests {
  private static func baseValues(
    recordName: String? = "rec-1"
  ) -> [String: ConfigValue] {
    var values: [String: ConfigValue] = [
      "container.identifier": .init(stringLiteral: "iCloud.com.test.App"),
      "api.token": .init(stringLiteral: "test-api-token"),
      "environment": .init(stringLiteral: "development"),
      "database": .init(stringLiteral: "private"),
    ]
    if let recordName {
      values["record.name"] = .init(stringLiteral: recordName)
    }
    return values
  }

  @Test("Parses defaults when only the required record.name is set")
  internal func parsesDefaults() async throws {
    let configuration = MistDemoConfiguration.testing(Self.baseValues())

    let config = try await DeleteConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.zone == "_defaultZone")
    #expect(config.recordType == "Note")
    #expect(config.recordName == "rec-1")
    #expect(config.recordChangeTag == nil)
    #expect(config.force == false)
    #expect(config.output == .json)
  }

  @Test("Parses custom zone, record type, and record change tag")
  internal func parsesCustomFields() async throws {
    var values = Self.baseValues()
    values["zone"] = .init(stringLiteral: "myZone")
    values["record.type"] = .init(stringLiteral: "Article")
    values["record.change.tag"] = .init(stringLiteral: "tag-7")
    let configuration = MistDemoConfiguration.testing(values)

    let config = try await DeleteConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.zone == "myZone")
    #expect(config.recordType == "Article")
    #expect(config.recordChangeTag == "tag-7")
  }

  @Test("Parses force flag from configuration")
  internal func parsesForceFlag() async throws {
    var values = Self.baseValues()
    values["force"] = .init(booleanLiteral: true)
    let configuration = MistDemoConfiguration.testing(values)

    let config = try await DeleteConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.force == true)
  }

  @Test("Throws recordNameRequired when record.name is missing")
  internal func throwsWhenRecordNameMissing() async throws {
    let configuration = MistDemoConfiguration.testing(
      Self.baseValues(recordName: nil)
    )

    await #expect(throws: DeleteError.self) {
      _ = try await DeleteConfig(
        configuration: configuration,
        base: nil
      )
    }
  }

  @Test("Output format defaults to json and accepts table")
  internal func parsesOutputFormat() async throws {
    var values = Self.baseValues()
    values["output.format"] = .init(stringLiteral: "table")
    var configuration = MistDemoConfiguration.testing(values)

    var config = try await DeleteConfig(
      configuration: configuration,
      base: nil
    )
    #expect(config.output == .table)

    values["output.format"] = .init(stringLiteral: "bogus")
    configuration = MistDemoConfiguration.testing(values)
    config = try await DeleteConfig(
      configuration: configuration,
      base: nil
    )
    #expect(config.output == .json)
  }

  @Test("Reuses an explicit base config")
  internal func reusesExplicitBase() async throws {
    let configuration = MistDemoConfiguration.testing(Self.baseValues())
    let baseConfig = try await MistDemoConfig()

    let config = try await DeleteConfig(
      configuration: configuration,
      base: baseConfig
    )

    #expect(config.base.containerIdentifier == baseConfig.containerIdentifier)
  }
}
