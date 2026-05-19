//
//  UploadAssetCommand.swift
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

internal import Foundation
internal import MistKit

/// Command to upload binary assets to CloudKit
public struct UploadAssetCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = UploadAssetConfig
  /// The command name.
  public static let commandName = "upload-asset"
  /// The command abstract.
  public static let abstract = "Upload binary assets to CloudKit"
  /// The command help text.
  public static let helpText = """
    UPLOAD-ASSET - Upload binary assets to CloudKit

    USAGE:
      mistdemo upload-asset --file <path> [options]

    REQUIRED:
      --file <path>              File to upload

    OPTIONS:
      --record-type <type>       Record type (default: Note)
      --field-name <field>       Asset field (default: image)
      --record-name <name>       Record name (auto-generated)
      --output-format <format>   Output format

    EXAMPLES:
      mistdemo upload-asset --file photo.jpg
      mistdemo upload-asset --file photo.jpg \\
        --record-type Photo --field-name thumbnail

    NOTES:
      Maximum file size: 15 MB.
      Upload URLs valid for 15 minutes.
    """

  private let config: UploadAssetConfig

  /// Creates a new instance.
  public init(config: UploadAssetConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    print("\n" + String(repeating: "=", count: 60))
    print("📤 Upload Asset to CloudKit")
    print(String(repeating: "=", count: 60))

    let fileURL = URL(fileURLWithPath: config.file)
    guard FileManager.default.fileExists(atPath: config.file)
    else {
      throw UploadAssetError.fileNotFound(config.file)
    }

    do {
      let data = try readAndValidateFile(fileURL: fileURL)
      let service = try MistKitClientFactory.create(
        for: config.base
      )
      let result = try await uploadAsset(
        data: data, service: service
      )
      try await attachAssetToRecord(
        result: result, service: service
      )
    } catch let error as UploadAssetError {
      throw error
    } catch let error as CloudKitError {
      throw UploadAssetError.operationFailed(
        error.localizedDescription
      )
    } catch {
      throw UploadAssetError.operationFailed(
        error.localizedDescription
      )
    }

    print("\n" + String(repeating: "=", count: 60))
    print("✅ Upload completed!")
    print(String(repeating: "=", count: 60))
  }

  private func readAndValidateFile(
    fileURL: URL
  ) throws -> Data {
    let data = try Data(contentsOf: fileURL)
    let maxSize: Int64 = 15 * 1_024 * 1_024
    if data.count > maxSize {
      throw UploadAssetError.fileTooLarge(
        Int64(data.count), maximum: maxSize
      )
    }
    let sizeInMB = Double(data.count) / 1_024 / 1_024
    let sizeStr = String(format: "%.2f", sizeInMB)
    print("\n📁 File: \(fileURL.lastPathComponent) (\(sizeStr) MB)")
    print("📝 Record Type: \(config.recordType)")
    return data
  }

  private func uploadAsset(
    data: Data,
    service: CloudKitService
  ) async throws -> AssetUploadReceipt {
    print("\n⬆️  Uploading...")
    let result = try await service.uploadAssets(
      data: data,
      recordType: config.recordType,
      fieldName: config.fieldName,
      recordName: config.recordName,
      database: config.base.database
    )
    print("\n✅ Asset uploaded!")
    print("   Record Name: \(result.recordName)")
    return result
  }

  private func attachAssetToRecord(
    result: AssetUploadReceipt,
    service: CloudKitService
  ) async throws {
    print("\n📝 Creating record with asset...")
    do {
      let recordInfo = try await createOrUpdateRecord(
        result: result, service: service
      )
      print("✅ Record Name: \(recordInfo.recordName)")
      try await outputResult(recordInfo, format: config.output)
    } catch {
      print("\n⚠️  Record operation failed:")
      print("   \(error.localizedDescription)")
    }
  }

  /// Create or update a record with the uploaded asset.
  private func createOrUpdateRecord(
    result: AssetUploadReceipt,
    service: CloudKitService
  ) async throws -> RecordInfo {
    var fields: [String: FieldValue] = [
      config.fieldName: .asset(result.asset)
    ]

    if let recordName = config.recordName {
      return try await updateExistingRecord(
        recordName: recordName,
        fields: fields,
        service: service
      )
    } else {
      if config.recordType == "Note" {
        fields["title"] = .string(
          "Uploaded Image - \(Date().formatted())"
        )
      }
      let newRecordName = UUID().uuidString.lowercased()
      return try await service.createRecord(
        recordType: config.recordType,
        recordName: newRecordName,
        fields: fields,
        database: config.base.database
      )
    }
  }

  private func updateExistingRecord(
    recordName: String,
    fields: [String: FieldValue],
    service: CloudKitService
  ) async throws -> RecordInfo {
    let existingRecords = try await service.lookupRecords(
      recordNames: [recordName],
      database: config.base.database
    )
    guard let existingRecord = existingRecords.first else {
      throw UploadAssetError.operationFailed(
        "Record '\(recordName)' not found"
      )
    }
    return try await service.updateRecord(
      recordType: config.recordType,
      recordName: recordName,
      fields: fields,
      recordChangeTag: existingRecord.recordChangeTag,
      database: config.base.database
    )
  }
}
