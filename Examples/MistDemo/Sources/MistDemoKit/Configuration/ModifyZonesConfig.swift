//
//  ModifyZonesConfig.swift
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

/// Configuration for the `modify-zones` command.
public struct ModifyZonesConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The list of zone operations to perform.
  public let operations: [ZoneOperationInput]
  /// The output format.
  public let output: OutputFormat

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    operations: [ZoneOperationInput],
    output: OutputFormat = .json
  ) {
    self.base = base
    self.operations = operations
    self.output = output
  }

  /// Parse configuration from command line arguments.
  public init(
    configuration: MistDemoConfiguration,
    base: MistDemoConfig?
  ) async throws {
    let baseConfig: MistDemoConfig
    if let base {
      baseConfig = base
    } else {
      baseConfig = try await MistDemoConfig(
        configuration: configuration,
        base: nil
      )
    }

    let operations = try Self.parseOperationsFromSources(configuration)

    let outputString =
      configuration.read(MistDemoKeys.Output.format)
    let output = OutputFormat(rawValue: outputString) ?? .json

    self.init(
      base: baseConfig,
      operations: operations,
      output: output
    )
  }

  /// Parse a zone-operations JSON envelope from data.
  ///
  /// Accepts the envelope form `{ "operations": [...] }`.
  public static func parseOperations(
    from data: Data
  ) throws -> [ZoneOperationInput] {
    do {
      let envelope = try JSONDecoder().decode(
        ZoneOperationsEnvelope.self,
        from: data
      )
      return envelope.operations
    } catch let error as ModifyZonesError {
      throw error
    } catch {
      throw ModifyZonesError.parsingFailed(error.localizedDescription)
    }
  }

  private static func parseOperationsFromSources(
    _ configReader: MistDemoConfiguration
  ) throws -> [ZoneOperationInput] {
    if let path = configReader.read(MistDemoKeys.Record.operationsFile) {
      do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try parseOperations(from: data)
      } catch let error as ModifyZonesError {
        throw error
      } catch {
        throw ModifyZonesError.operationsFileError(
          path,
          error.localizedDescription
        )
      }
    }

    if configReader.read(MistDemoKeys.Record.stdin) {
      let stdinData = FileHandle.standardInput.readDataToEndOfFile()
      guard !stdinData.isEmpty else {
        throw ModifyZonesError.emptyStdin
      }
      return try parseOperations(from: stdinData)
    }

    throw ModifyZonesError.operationsRequired
  }
}
