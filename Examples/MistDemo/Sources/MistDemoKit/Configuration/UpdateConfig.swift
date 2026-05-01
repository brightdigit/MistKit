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

public import Foundation
public import MistKit
public import ConfigKeyKit

/// Configuration for update command
public struct UpdateConfig: Sendable, ConfigurationParseable {
    public typealias ConfigReader = MistDemoConfiguration
    public typealias BaseConfig = MistDemoConfig

    public let base: MistDemoConfig
    public let zone: String
    public let recordType: String
    public let recordName: String
    public let recordChangeTag: String?
    public let fields: [Field]
    public let output: OutputFormat

    public init(
        base: MistDemoConfig,
        zone: String = "_defaultZone",
        recordType: String = "Note",
        recordName: String,
        recordChangeTag: String? = nil,
        fields: [Field] = [],
        output: OutputFormat = .json
    ) {
        self.base = base
        self.zone = zone
        self.recordType = recordType
        self.recordName = recordName
        self.recordChangeTag = recordChangeTag
        self.fields = fields
        self.output = output
    }

    /// Parse configuration from command line arguments
    public init(configuration: MistDemoConfiguration, base: MistDemoConfig?) async throws {
        let configReader = configuration
        let baseConfig: MistDemoConfig
        if let base = base {
            baseConfig = base
        } else {
            baseConfig = try await MistDemoConfig(configuration: configuration, base: nil)
        }

        // Parse update-specific options
        let zone = configReader.string(forKey: MistDemoConstants.ConfigKeys.zone, default: MistDemoConstants.Defaults.zone) ?? MistDemoConstants.Defaults.zone
        let recordType = configReader.string(forKey: MistDemoConstants.ConfigKeys.recordType, default: MistDemoConstants.Defaults.recordType) ?? MistDemoConstants.Defaults.recordType

        // Validate recordName is provided (REQUIRED for update)
        guard let recordName = configReader.string(forKey: MistDemoConstants.ConfigKeys.recordName) else {
            throw UpdateError.recordNameRequired
        }

        let recordChangeTag = configReader.string(forKey: MistDemoConstants.ConfigKeys.recordChangeTag)

        // Parse fields from various sources
        let fields = try Self.parseFieldsFromSources(configReader)

        // Parse output format
        let outputString = configReader.string(forKey: MistDemoConstants.ConfigKeys.outputFormat, default: MistDemoConstants.Defaults.outputFormat) ?? MistDemoConstants.Defaults.outputFormat
        let output = OutputFormat(rawValue: outputString) ?? .json

        self.init(
            base: baseConfig,
            zone: zone,
            recordType: recordType,
            recordName: recordName,
            recordChangeTag: recordChangeTag,
            fields: fields,
            output: output
        )
    }

    private static func parseFieldsFromSources(_ configReader: MistDemoConfiguration) throws -> [Field] {
        var fields: [Field] = []

        // 1. Parse inline field definitions
        if let fieldString = configReader.string(forKey: "field") {
            let fieldDefinitions = fieldString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            let inlineFields = try Field.parseFields(fieldDefinitions)
            fields.append(contentsOf: inlineFields)
        }

        // 2. Parse from JSON file
        if let jsonFile = configReader.string(forKey: MistDemoConstants.ConfigKeys.jsonFile) {
            let jsonFields = try parseFieldsFromJSONFile(jsonFile)
            fields.append(contentsOf: jsonFields)
        }

        // 3. Parse from stdin (check if data is available)
        if configReader.bool(forKey: MistDemoConstants.ConfigKeys.stdin, default: false) {
            let stdinFields = try parseFieldsFromStdin()
            fields.append(contentsOf: stdinFields)
        }

        guard !fields.isEmpty else {
            throw UpdateError.noFieldsProvided
        }

        return fields
    }

    /// Parse fields from JSON file
    private static func parseFieldsFromJSONFile(_ filePath: String) throws -> [Field] {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
            return try fieldsInput.toFields()
        } catch {
            throw UpdateError.jsonFileError(filePath, error.localizedDescription)
        }
    }

    /// Parse fields from stdin
    private static func parseFieldsFromStdin() throws -> [Field] {
        let stdinData = FileHandle.standardInput.readDataToEndOfFile()

        guard !stdinData.isEmpty else {
            throw UpdateError.emptyStdin
        }

        do {
            let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: stdinData)
            return try fieldsInput.toFields()
        } catch {
            throw UpdateError.stdinError(error.localizedDescription)
        }
    }
}
