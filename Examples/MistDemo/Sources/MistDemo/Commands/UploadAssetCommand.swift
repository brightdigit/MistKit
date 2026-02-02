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

import Foundation
import MistKit

/// Command to upload binary assets to CloudKit
public struct UploadAssetCommand: MistDemoCommand, OutputFormatting {
    public typealias Config = UploadAssetConfig
    public static let commandName = "upload-asset"
    public static let abstract = "Upload binary assets to CloudKit"
    public static let helpText = """
        UPLOAD-ASSET - Upload binary assets to CloudKit

        USAGE:
            mistdemo upload-asset --file <path> [options]

        REQUIRED OPTIONS:
            --file <path>              Path to the file to upload

        OPTIONAL:
            --record-type <type>       Record type name (default: "Note")
            --field-name <field>       Asset field name (default: "image")
            --record-name <name>       Unique record name (optional, auto-generated if omitted)
            --api-token <token>        CloudKit API token
            --output-format <format>   Output format: json, table, csv, yaml

        EXAMPLES:
            # Upload with defaults (Note.image)
            mistdemo upload-asset --file photo.jpg

            # Upload to custom record type and field
            mistdemo upload-asset \\
              --file photo.jpg \\
              --record-type Photo \\
              --field-name thumbnail

            # Upload with specific record name
            mistdemo upload-asset \\
              --file document.pdf \\
              --record-type Document \\
              --field-name file \\
              --record-name my-document-123

        WORKFLOW:
            1. Upload the asset using this command
            2. Note the returned record name and asset details
            3. Use 'create' or 'update' command to associate the asset with a record

        NOTES:
            - Maximum file size: 15 MB
            - Upload URLs valid for 15 minutes
            - With web authentication: uploads to private database
            - With API-only authentication: uploads to public database
            - Returns asset metadata (receipt, checksums) needed for record operations
            - Defaults match MistDemo schema: Note record type, image field
        """

    private let config: UploadAssetConfig

    public init(config: UploadAssetConfig) {
        self.config = config
    }

    public func execute() async throws {
        print("\n" + String(repeating: "=", count: 60))
        print("📤 Upload Asset to CloudKit")
        print(String(repeating: "=", count: 60))

        // Validate file exists
        let fileURL = URL(fileURLWithPath: config.file)
        guard FileManager.default.fileExists(atPath: config.file) else {
            throw UploadAssetError.fileNotFound(config.file)
        }

        do {
            // Read file data
            let data = try Data(contentsOf: fileURL)
            let sizeInMB = Double(data.count) / 1024 / 1024
            print("\n📁 File: \(fileURL.lastPathComponent) (\(String(format: "%.2f", sizeInMB)) MB)")
            print("📝 Record Type: \(config.recordType)")
            print("🏷️  Field Name: \(config.fieldName)")
            if let recordName = config.recordName {
                print("🆔 Record Name: \(recordName)")
            }

            // Check file size (15 MB limit)
            let maxSize: Int64 = 15 * 1024 * 1024
            if data.count > maxSize {
                throw UploadAssetError.fileTooLarge(Int64(data.count), maximum: maxSize)
            }

            // Create CloudKit service (will use appropriate database based on authentication)
            // With web-auth: private database, with API-only: public database
            let service = try MistKitClientFactory.create(from: config.base)

            // Upload asset
            print("\n⬆️  Uploading...")
            let result = try await service.uploadAssets(
                data: data,
                recordType: config.recordType,
                fieldName: config.fieldName,
                recordName: config.recordName
            )

            print("\n✅ Asset uploaded successfully!")
            print("   Record Name: \(result.recordName)")
            print("   Field Name: \(result.fieldName)")
            if let receipt = result.asset.receipt {
                print("   Receipt: \(receipt.prefix(40))...")
            }

            // Now create/update the record with the asset
            print("\n📝 Creating record with asset...")
            do {
                let recordInfo = try await createOrUpdateRecordWithAsset(
                    result: result,
                    service: service
                )

                if config.recordName != nil {
                    print("✅ Record updated with asset!")
                } else {
                    print("✅ New record created with asset!")
                }

                print("   Record Name: \(recordInfo.recordName)")
                print("   Record Type: \(recordInfo.recordType)")
                if let changeTag = recordInfo.recordChangeTag {
                    print("   Change Tag: \(changeTag)")
                }

                // Output in requested format
                try await outputResult(recordInfo, format: config.output)

            } catch {
                print("\n⚠️  Asset uploaded but record operation failed:")
                print("   \(error.localizedDescription)")
                print("\n   The asset is uploaded but not associated with a record.")
                print("   Asset details:")
                print("   - Record Name: \(result.recordName)")
                print("   - Field Name: \(result.fieldName)")
                // Don't throw - asset upload succeeded
            }

        } catch let error as CloudKitError {
            print("\n❌ CloudKit Error: \(error)")
            throw UploadAssetError.operationFailed(error.localizedDescription)
        } catch let error as UploadAssetError {
            print("\n❌ \(error.localizedDescription)")
            throw error
        } catch {
            print("\n❌ Error: \(error)")
            throw UploadAssetError.operationFailed(error.localizedDescription)
        }

        print("\n" + String(repeating: "=", count: 60))
        print("✅ Upload completed!")
        print(String(repeating: "=", count: 60))
    }

    /// Create or update a record with the uploaded asset
    /// The asset metadata (receipt, checksums) from CloudKit must be used in the record
    private func createOrUpdateRecordWithAsset(
        result: AssetUploadResult,
        service: CloudKitService
    ) async throws -> RecordInfo {
        // Use the complete asset data from the upload result
        // This contains the receipt and checksums returned by CloudKit
        var fields: [String: FieldValue] = [
            config.fieldName: .asset(result.asset)
        ]

        // Debug: Print asset details
        print("   Asset details:")
        print("     - Receipt: \(result.asset.receipt ?? "nil")")
        print("     - File checksum: \(result.asset.fileChecksum ?? "nil")")
        print("     - Size: \(result.asset.size.map(String.init) ?? "nil")")
        print("     - Wrapping key: \(result.asset.wrappingKey ?? "nil")")
        print("     - Reference checksum: \(result.asset.referenceChecksum ?? "nil")")

        if let recordName = config.recordName {
            // User provided recordName → UPDATE existing record's asset field
            // First fetch the existing record to get its current recordChangeTag
            print("   Fetching existing record to get change tag...")
            let existingRecords = try await service.lookupRecords(
                recordNames: [recordName]
            )

            guard let existingRecord = existingRecords.first else {
                throw UploadAssetError.operationFailed("Record '\(recordName)' not found")
            }

            print("   Updating record with change tag: \(existingRecord.recordChangeTag ?? "nil")")
            return try await service.updateRecord(
                recordType: config.recordType,
                recordName: recordName,
                fields: fields,
                recordChangeTag: existingRecord.recordChangeTag
            )
        } else {
            // No recordName → CREATE new record with the asset field
            // For Note records, add a default title to ensure validity
            if config.recordType == "Note" {
                fields["title"] = .string("Uploaded Image - \(Date().formatted())")
            }

            // Generate a NEW recordName for the record (don't reuse the upload token's recordName)
            // The upload recordName is just for the asset upload, not the actual record
            let newRecordName = UUID().uuidString.lowercased()
            print("   Creating record with new name: \(newRecordName)")

            return try await service.createRecord(
                recordType: config.recordType,
                recordName: newRecordName,
                fields: fields
            )
        }
    }
}
