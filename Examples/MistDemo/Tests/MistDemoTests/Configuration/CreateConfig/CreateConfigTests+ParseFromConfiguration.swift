//
//  CreateConfigTests+ParseFromConfiguration.swift
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

extension CreateConfigTests {
  @Suite("Parse From Configuration")
  internal struct ParseFromConfiguration {
    private static func baseValues(
      withFields fieldString: String? = "title:string:hello"
    ) -> [String: ConfigValue] {
      var values: [String: ConfigValue] = [
        "container.identifier": .init(stringLiteral: "iCloud.com.test.App"),
        "api.token": .init(stringLiteral: "test-api-token"),
        "environment": .init(stringLiteral: "development"),
        "database": .init(stringLiteral: "private"),
      ]
      if let fieldString {
        values["field"] = .init(stringLiteral: fieldString)
      }
      return values
    }

    @Test("Parses defaults when only field= is provided")
    internal func parsesDefaults() async throws {
      let configuration = MistDemoConfiguration.testing(Self.baseValues())
      let config = try await CreateConfig(
        configuration: configuration,
        base: nil
      )

      #expect(config.zone == "_defaultZone")
      #expect(config.recordType == "Note")
      #expect(config.recordName == nil)
      #expect(config.fields.count == 1)
      #expect(config.fields.first?.name == "title")
      #expect(config.output == .json)
    }

    @Test("Parses custom zone, record type, and record name")
    internal func parsesCustomIdentifiers() async throws {
      var values = Self.baseValues()
      values["zone"] = .init(stringLiteral: "myZone")
      values["record.type"] = .init(stringLiteral: "Article")
      values["record.name"] = .init(stringLiteral: "rec-42")
      let configuration = MistDemoConfiguration.testing(values)

      let config = try await CreateConfig(
        configuration: configuration,
        base: nil
      )

      #expect(config.zone == "myZone")
      #expect(config.recordType == "Article")
      #expect(config.recordName == "rec-42")
    }

    @Test("Parses comma-separated inline field definitions")
    internal func parsesInlineFields() async throws {
      var values = Self.baseValues(withFields: nil)
      values["field"] =
        .init(stringLiteral: "title:string:hello, count:int:7 ,active:bool:true")
      let configuration = MistDemoConfiguration.testing(values)

      let config = try await CreateConfig(
        configuration: configuration,
        base: nil
      )

      #expect(config.fields.count == 3)
      let names = config.fields.map(\.name)
      #expect(names.contains("title"))
      #expect(names.contains("count"))
      #expect(names.contains("active"))
    }

    @Test("Parses fields from a JSON file")
    internal func parsesFieldsFromJSONFile() async throws {
      let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(
        "mistdemo-create-\(UUID().uuidString).json"
      )
      defer { try? FileManager.default.removeItem(at: tmp) }

      let json = #"{ "title": "from-file", "count": 3 }"#
      try json.data(using: .utf8)!.write(to: tmp)

      var values = Self.baseValues(withFields: nil)
      values["json.file"] = .init(stringLiteral: tmp.path)
      let configuration = MistDemoConfiguration.testing(values)

      let config = try await CreateConfig(
        configuration: configuration,
        base: nil
      )

      #expect(config.fields.count == 2)
      let byName = Dictionary(
        uniqueKeysWithValues: config.fields.map { ($0.name, $0) }
      )
      #expect(byName["title"]?.value == "from-file")
      #expect(byName["count"]?.value == "3")
    }

    @Test("Throws noFieldsProvided when no inline / file / stdin source is set")
    internal func throwsWhenNoFields() async throws {
      let configuration = MistDemoConfiguration.testing(
        Self.baseValues(withFields: nil)
      )

      await #expect(throws: CreateError.self) {
        _ = try await CreateConfig(
          configuration: configuration,
          base: nil
        )
      }
    }

    @Test("Throws jsonFileError when JSON file is unreadable")
    internal func throwsForBadJSONFile() async throws {
      var values = Self.baseValues(withFields: nil)
      values["json.file"] = .init(
        stringLiteral: "/nonexistent/\(UUID().uuidString).json"
      )
      let configuration = MistDemoConfiguration.testing(values)

      await #expect(throws: CreateError.self) {
        _ = try await CreateConfig(
          configuration: configuration,
          base: nil
        )
      }
    }

    @Test(
      "Output format parses from string and falls back to .json on unknown values"
    )
    internal func parsesOutputFormats() async throws {
      var values = Self.baseValues()
      values["output.format"] = .init(stringLiteral: "table")
      var configuration = MistDemoConfiguration.testing(values)

      var config = try await CreateConfig(
        configuration: configuration,
        base: nil
      )
      #expect(config.output == .table)

      values["output.format"] = .init(stringLiteral: "not-a-real-format")
      configuration = MistDemoConfiguration.testing(values)

      config = try await CreateConfig(
        configuration: configuration,
        base: nil
      )
      #expect(config.output == .json)
    }

    @Test("Reuses provided base config without re-parsing")
    internal func reusesExplicitBase() async throws {
      let baseConfig = try await MistDemoConfig()
      let configuration = MistDemoConfiguration.testing(Self.baseValues())

      let config = try await CreateConfig(
        configuration: configuration,
        base: baseConfig
      )

      #expect(config.base.containerIdentifier == baseConfig.containerIdentifier)
    }
  }
}
