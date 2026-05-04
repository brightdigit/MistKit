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

/// Operation type from the JSON ops file
public enum ModifyOperationKind: String, Codable, Sendable {
  case create
  case update
  case delete
}

/// One operation parsed from the modify ops JSON payload
public struct ModifyOperationInput: Codable, Sendable {
  public let op: ModifyOperationKind
  public let recordType: String
  public let recordName: String?
  public let fields: FieldsInput?
  public let recordChangeTag: String?

  public init(
    op: ModifyOperationKind,
    recordType: String,
    recordName: String? = nil,
    fields: FieldsInput? = nil,
    recordChangeTag: String? = nil
  ) {
    self.op = op
    self.recordType = recordType
    self.recordName = recordName
    self.fields = fields
    self.recordChangeTag = recordChangeTag
  }

  /// Convert this operation input into a MistKit RecordOperation, validating
  /// that update/delete have a recordName.
  public func toRecordOperation(index: Int) throws -> RecordOperation {
    let cloudKitFields: [String: FieldValue]
    if let fields {
      let domainFields = try fields.toFields()
      cloudKitFields = try domainFields.toCloudKitFields()
    } else {
      cloudKitFields = [:]
    }

    switch op {
    case .create:
      return RecordOperation.create(
        recordType: recordType,
        recordName: recordName,
        fields: cloudKitFields
      )
    case .update:
      guard let recordName else {
        throw ModifyError.missingRecordName(opIndex: index, op: op.rawValue)
      }
      return RecordOperation.update(
        recordType: recordType,
        recordName: recordName,
        fields: cloudKitFields,
        recordChangeTag: recordChangeTag
      )
    case .delete:
      guard let recordName else {
        throw ModifyError.missingRecordName(opIndex: index, op: op.rawValue)
      }
      return RecordOperation.delete(
        recordType: recordType,
        recordName: recordName,
        recordChangeTag: recordChangeTag
      )
    }
  }
}

/// Configuration for modify command
public struct ModifyConfig: Sendable, ConfigurationParseable {
  public typealias ConfigReader = MistDemoConfiguration
  public typealias BaseConfig = MistDemoConfig

  public let base: MistDemoConfig
  public let operations: [ModifyOperationInput]
  public let atomic: Bool
  public let output: OutputFormat

  public init(
    base: MistDemoConfig,
    operations: [ModifyOperationInput],
    atomic: Bool = false,
    output: OutputFormat = .json
  ) {
    self.base = base
    self.operations = operations
    self.atomic = atomic
    self.output = output
  }

  public init(configuration: MistDemoConfiguration, base: MistDemoConfig?) async throws {
    let configReader = configuration
    let baseConfig: MistDemoConfig
    if let base {
      baseConfig = base
    } else {
      baseConfig = try await MistDemoConfig(configuration: configuration, base: nil)
    }

    let operations = try Self.parseOperationsFromSources(configReader)

    let atomic = configReader.bool(forKey: MistDemoConstants.ConfigKeys.atomic, default: false)

    let outputString =
      configReader.string(
        forKey: MistDemoConstants.ConfigKeys.outputFormat,
        default: MistDemoConstants.Defaults.outputFormat) ?? MistDemoConstants.Defaults.outputFormat
    let output = OutputFormat(rawValue: outputString) ?? .json

    self.init(
      base: baseConfig,
      operations: operations,
      atomic: atomic,
      output: output
    )
  }

  /// Parse a JSON array of operations from a file path or stdin.
  public static func parseOperations(from data: Data) throws -> [ModifyOperationInput] {
    do {
      return try JSONDecoder().decode([ModifyOperationInput].self, from: data)
    } catch let DecodingError.dataCorrupted(context) where context.codingPath.isEmpty {
      // Likely an invalid op string ("foo") at the root — surface as invalidOperationType when possible
      throw ModifyError.stdinError(context.debugDescription)
    } catch let error as ModifyError {
      throw error
    } catch {
      throw ModifyError.stdinError(error.localizedDescription)
    }
  }

  private static func parseOperationsFromSources(_ configReader: MistDemoConfiguration) throws
    -> [ModifyOperationInput]
  {
    if let path = configReader.string(forKey: MistDemoConstants.ConfigKeys.operationsFile) {
      do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try parseOperations(from: data)
      } catch let error as ModifyError {
        throw error
      } catch {
        throw ModifyError.operationsFileError(path, error.localizedDescription)
      }
    }

    if configReader.bool(forKey: MistDemoConstants.ConfigKeys.stdin, default: false) {
      let stdinData = FileHandle.standardInput.readDataToEndOfFile()
      guard !stdinData.isEmpty else {
        throw ModifyError.emptyStdin
      }
      return try parseOperations(from: stdinData)
    }

    throw ModifyError.operationsRequired
  }
}
