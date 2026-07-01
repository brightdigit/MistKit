//
//  ModifyConfig.swift
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
public import Foundation
public import MistKit

/// Configuration for modify command.
public struct ModifyConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The list of modify operations to perform.
  public let operations: [ModifyOperationInput]
  /// Whether to perform operations atomically.
  public let atomic: Bool
  /// The optional target zone for the operations.
  public let zone: String?
  /// The optional field names limiting the fields returned in the response.
  public let desiredKeys: [String]?
  /// Whether numeric field values are returned as strings.
  public let numbersAsStrings: Bool?
  /// The output format.
  public let output: OutputFormat

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    operations: [ModifyOperationInput],
    atomic: Bool = false,
    zone: String? = nil,
    desiredKeys: [String]? = nil,
    numbersAsStrings: Bool? = nil,
    output: OutputFormat = .json
  ) {
    self.base = base
    self.operations = operations
    self.atomic = atomic
    self.zone = zone
    self.desiredKeys = desiredKeys
    self.numbersAsStrings = numbersAsStrings
    self.output = output
  }

  /// Parse configuration from command line arguments.
  public init(
    configuration: MistDemoConfiguration,
    base: MistDemoConfig?
  ) async throws {
    let configReader = configuration
    let baseConfig: MistDemoConfig
    if let base {
      baseConfig = base
    } else {
      baseConfig = try await MistDemoConfig(
        configuration: configuration,
        base: nil
      )
    }

    let operations = try Self.parseOperationsFromSources(
      configReader
    )

    let atomic = configReader.bool(
      forKey: MistDemoConstants.ConfigKeys.atomic,
      default: false
    )

    let zone = configReader.string(
      forKey: MistDemoConstants.ConfigKeys.zone
    )
    let desiredKeys = configReader.commaSeparatedList(
      forKey: MistDemoConstants.ConfigKeys.fields
    )
    let numbersAsStrings = configReader.optionalBool(
      forKey: MistDemoConstants.ConfigKeys.numbersAsStrings
    )

    let outputString =
      configReader.string(
        forKey: MistDemoConstants.ConfigKeys.outputFormat,
        default: MistDemoConstants.Defaults.outputFormat
      ) ?? MistDemoConstants.Defaults.outputFormat
    let output = OutputFormat(rawValue: outputString) ?? .json

    self.init(
      base: baseConfig,
      operations: operations,
      atomic: atomic,
      zone: zone,
      desiredKeys: desiredKeys,
      numbersAsStrings: numbersAsStrings,
      output: output
    )
  }

  /// Parse a JSON array of operations from data.
  public static func parseOperations(
    from data: Data
  ) throws -> [ModifyOperationInput] {
    do {
      return try JSONDecoder().decode(
        [ModifyOperationInput].self,
        from: data
      )
    } catch let DecodingError.dataCorrupted(context) where context.codingPath.isEmpty {
      throw ModifyError.stdinError(context.debugDescription)
    } catch let error as ModifyError {
      throw error
    } catch {
      throw ModifyError.stdinError(error.localizedDescription)
    }
  }

  private static func parseOperationsFromSources(
    _ configReader: MistDemoConfiguration
  ) throws -> [ModifyOperationInput] {
    if let path = configReader.string(
      forKey: MistDemoConstants.ConfigKeys.operationsFile
    ) {
      do {
        let data = try Data(
          contentsOf: URL(fileURLWithPath: path)
        )
        return try parseOperations(from: data)
      } catch let error as ModifyError {
        throw error
      } catch {
        throw ModifyError.operationsFileError(
          path,
          error.localizedDescription
        )
      }
    }

    if configReader.bool(
      forKey: MistDemoConstants.ConfigKeys.stdin,
      default: false
    ) {
      let stdinData = FileHandle.standardInput.readDataToEndOfFile()
      guard !stdinData.isEmpty else {
        throw ModifyError.emptyStdin
      }
      return try parseOperations(from: stdinData)
    }

    throw ModifyError.operationsRequired
  }
}
