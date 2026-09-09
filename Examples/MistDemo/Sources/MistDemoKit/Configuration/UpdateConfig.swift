//
//  UpdateConfig.swift
//  MistDemo
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

public import ConfigKeyKit
internal import Foundation
public import MistKit

/// Configuration for update command.
public struct UpdateConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The CloudKit zone name.
  public let zone: String
  /// The CloudKit record type.
  public let recordType: String
  /// The record name to update.
  public let recordName: String
  /// The optional record change tag for conflict detection.
  public let recordChangeTag: String?
  /// Whether to force update without change tag.
  public let force: Bool
  /// The fields to update.
  public let fields: [Field]
  /// The output format.
  public let output: OutputFormat

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    zone: String = "_defaultZone",
    recordType: String = "Note",
    recordName: String,
    recordChangeTag: String? = nil,
    force: Bool = false,
    fields: [Field] = [],
    output: OutputFormat = .json
  ) {
    self.base = base
    self.zone = zone
    self.recordType = recordType
    self.recordName = recordName
    self.recordChangeTag = recordChangeTag
    self.force = force
    self.fields = fields
    self.output = output
  }

  /// Parse configuration from command line arguments.
  public init(
    configuration: MistDemoConfiguration,
    base: MistDemoConfig?
  ) async throws {
    let configReader = configuration
    let baseConfig: MistDemoConfig
    if let base = base {
      baseConfig = base
    } else {
      baseConfig = try await MistDemoConfig(
        configuration: configuration,
        base: nil
      )
    }

    // Parse update-specific options
    let zone =
      configReader.read(MistDemoKeys.Query.zone)
    let recordType =
      configReader.read(MistDemoKeys.Record.recordType)

    // Validate recordName is provided (REQUIRED for update)
    guard
      let recordName = configReader.read(MistDemoKeys.Record.recordName)
    else {
      throw UpdateError.recordNameRequired
    }

    let recordChangeTag = configReader.read(MistDemoKeys.Record.recordChangeTag)
    let force = configReader.read(MistDemoKeys.Record.force)

    // Parse fields from various sources
    let fields = try Self.parseFieldsFromSources(configReader)

    // Parse output format
    let outputString =
      configReader.read(MistDemoKeys.Output.format)
    let output = OutputFormat(rawValue: outputString) ?? .json

    self.init(
      base: baseConfig,
      zone: zone,
      recordType: recordType,
      recordName: recordName,
      recordChangeTag: recordChangeTag,
      force: force,
      fields: fields,
      output: output
    )
  }

  private static func parseFieldsFromSources(
    _ configReader: MistDemoConfiguration
  ) throws -> [Field] {
    var fields: [Field] = []

    // 1. Parse inline field definitions
    if let fieldString = configReader.read(MistDemoKeys.Record.field) {
      let fieldDefinitions = fieldString.split(separator: ",").map {
        String($0).trimmingCharacters(in: .whitespaces)
      }
      let inlineFields = try Field.parseFields(fieldDefinitions)
      fields.append(contentsOf: inlineFields)
    }

    // 2. Parse from JSON file
    if let jsonFile = configReader.read(MistDemoKeys.Record.jsonFile) {
      let jsonFields = try parseFieldsFromJSONFile(jsonFile)
      fields.append(contentsOf: jsonFields)
    }

    // 3. Parse from stdin (check if data is available)
    if configReader.read(MistDemoKeys.Record.stdin) {
      let stdinFields = try parseFieldsFromStdin()
      fields.append(contentsOf: stdinFields)
    }

    guard !fields.isEmpty else {
      throw UpdateError.noFieldsProvided
    }

    return fields
  }

  /// Parse fields from JSON file.
  private static func parseFieldsFromJSONFile(
    _ filePath: String
  ) throws -> [Field] {
    do {
      let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
      let fieldsInput = try JSONDecoder().decode(
        FieldsInput.self,
        from: data
      )
      return try fieldsInput.toFields()
    } catch {
      throw UpdateError.jsonFileError(
        filePath,
        error.localizedDescription
      )
    }
  }

  /// Parse fields from stdin.
  private static func parseFieldsFromStdin() throws -> [Field] {
    let stdinData = FileHandle.standardInput.readDataToEndOfFile()

    guard !stdinData.isEmpty else {
      throw UpdateError.emptyStdin
    }

    do {
      let fieldsInput = try JSONDecoder().decode(
        FieldsInput.self,
        from: stdinData
      )
      return try fieldsInput.toFields()
    } catch {
      throw UpdateError.stdinError(error.localizedDescription)
    }
  }
}
