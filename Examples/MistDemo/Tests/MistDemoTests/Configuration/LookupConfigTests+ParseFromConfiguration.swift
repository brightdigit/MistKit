//
//  LookupConfigTests+ParseFromConfiguration.swift
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

extension LookupConfigTests {
  private static func baseValues() -> [String: ConfigValue] {
    [
      "container.identifier": .init(stringLiteral: "iCloud.com.test.App"),
      "api.token": .init(stringLiteral: "test-api-token"),
      "environment": .init(stringLiteral: "development"),
      "database": .init(stringLiteral: "private"),
    ]
  }

  @Test("Parses comma-separated record.names")
  internal func parsesRecordNamesList() async throws {
    var values = Self.baseValues()
    values["record.names"] = .init(
      stringLiteral: " rec-1 , rec-2,rec-3 "
    )
    let configuration = MistDemoConfiguration.testing(values)

    let config = try await LookupConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.recordNames == ["rec-1", "rec-2", "rec-3"])
  }

  @Test("Falls back to singular record.name when record.names is unset")
  internal func parsesSingularRecordNameFallback() async throws {
    var values = Self.baseValues()
    values["record.name"] = .init(stringLiteral: "only-one")
    let configuration = MistDemoConfiguration.testing(values)

    let config = try await LookupConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.recordNames == ["only-one"])
  }

  @Test("Throws recordNamesRequired when no record name is configured")
  internal func throwsForMissingRecordNames() async throws {
    let configuration = MistDemoConfiguration.testing(Self.baseValues())

    await #expect(throws: LookupError.self) {
      _ = try await LookupConfig(
        configuration: configuration,
        base: nil
      )
    }
  }

  @Test("Parses comma-separated fields filter")
  internal func parsesFieldsFilter() async throws {
    var values = Self.baseValues()
    values["record.name"] = .init(stringLiteral: "rec-1")
    values["fields"] = .init(stringLiteral: "title, body ,author")
    let configuration = MistDemoConfiguration.testing(values)

    let config = try await LookupConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.fields == ["title", "body", "author"])
  }

  @Test("Defaults output format to json when unset")
  internal func defaultsOutputFormat() async throws {
    var values = Self.baseValues()
    values["record.name"] = .init(stringLiteral: "rec-1")
    let configuration = MistDemoConfiguration.testing(values)

    let config = try await LookupConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.output == .json)
  }

  @Test("Honors custom output format and falls back to json on unknown")
  internal func parsesCustomOutputFormat() async throws {
    var values = Self.baseValues()
    values["record.name"] = .init(stringLiteral: "rec-1")
    values["output.format"] = .init(stringLiteral: "table")
    var configuration = MistDemoConfiguration.testing(values)

    var config = try await LookupConfig(
      configuration: configuration,
      base: nil
    )
    #expect(config.output == .table)

    values["output.format"] = .init(stringLiteral: "definitely-not-real")
    configuration = MistDemoConfiguration.testing(values)
    config = try await LookupConfig(
      configuration: configuration,
      base: nil
    )
    #expect(config.output == .json)
  }

  @Test("Reuses an explicit base config")
  internal func reusesExplicitBase() async throws {
    var values = Self.baseValues()
    values["record.name"] = .init(stringLiteral: "rec-1")
    let configuration = MistDemoConfiguration.testing(values)

    let baseConfig = try await MistDemoConfig()
    let config = try await LookupConfig(
      configuration: configuration,
      base: baseConfig
    )

    #expect(config.base.containerIdentifier == baseConfig.containerIdentifier)
  }
}
