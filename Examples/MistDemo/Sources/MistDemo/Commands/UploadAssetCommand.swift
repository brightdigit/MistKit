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
            mistdemo upload-asset <file-path> [options]

        ARGUMENTS:
            <file-path>                Path to the file to upload

        OPTIONS:
            --api-token <token>        CloudKit API token
            --create-record <type>     Create a record of this type with the uploaded asset
            --output-format <format>   Output format: json, table, csv, yaml

        EXAMPLES:
            # Upload a photo
            mistdemo upload-asset photo.jpg --api-token YOUR_TOKEN

            # Upload and create a record
            mistdemo upload-asset document.pdf \\
              --create-record Document \\
              --api-token YOUR_TOKEN

        NOTES:
            - Maximum file size: 250 MB
            - Supported in public database only (API-only authentication)
            - Upload tokens must be associated with a record within a reasonable time
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

            // Check file size (250 MB limit)
            let maxSize: Int64 = 250 * 1024 * 1024
            if data.count > maxSize {
                throw UploadAssetError.fileTooLarge(Int64(data.count), maximum: maxSize)
            }

            // Create CloudKit service for public database (upload assets only works with public)
            let service = try MistKitClientFactory.createForPublicDatabase(from: config.base)

            // Upload asset
            print("⬆️  Uploading...")
            let result = try await service.uploadAssets(data: data)

            print("\n✅ Upload successful!")
            print("🎫 Received \(result.tokens.count) token(s):")
            for (index, token) in result.tokens.enumerated() {
                print("   Token \(index + 1):")
                if let url = token.url {
                    print("      URL: \(url.prefix(50))...")
                }
                if let recordName = token.recordName {
                    print("      Record: \(recordName)")
                }
                if let fieldName = token.fieldName {
                    print("      Field: \(fieldName)")
                }
            }

            // Optional: Create record with asset
            if let recordType = config.createRecord, let token = result.tokens.first {
                print("\n📝 Creating \(recordType) record with asset...")
                try await createRecordWithAsset(
                    service: service,
                    recordType: recordType,
                    filename: fileURL.lastPathComponent,
                    token: token,
                    fileSize: data.count
                )
            }

            // Output result in requested format
            try await outputUploadResult(result, format: config.output)

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

    /// Create a record with the uploaded asset
    private func createRecordWithAsset(
        service: CloudKitService,
        recordType: String,
        filename: String,
        token: AssetUploadToken,
        fileSize: Int
    ) async throws {
        let asset = FieldValue.Asset(
            fileChecksum: nil,
            size: Int64(fileSize),
            referenceChecksum: nil,
            wrappingKey: nil,
            receipt: nil,
            downloadURL: token.url
        )

        let record = try await service.createRecord(
            recordType: recordType,
            fields: [
                "filename": .string(filename),
                "file": .asset(asset)
            ]
        )

        print("   ✅ Created record: \(record.recordName)")
        print("   📝 Type: \(record.recordType)")
        print("   🆔 Record ID: \(record.recordName)")
    }

    /// Output upload result in the requested format
    private func outputUploadResult(_ result: AssetUploadResult, format: OutputFormat) async throws {
        // For now, we've already printed the result above in a user-friendly format
        // If JSON/table output is needed, implement it here
        switch format {
        case .json:
            // Already displayed in console output
            break
        case .table, .csv, .yaml:
            // Could implement formatted output here if needed
            break
        }
    }
}
