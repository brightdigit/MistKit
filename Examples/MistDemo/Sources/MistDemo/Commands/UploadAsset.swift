//
//  UploadAsset.swift
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

import ArgumentParser
import Foundation
import MistKit

/// Upload binary assets to CloudKit
struct UploadAsset: AsyncParsableCommand, CloudKitCommand {
    static let configuration = CommandConfiguration(
        commandName: "upload-asset",
        abstract: "Upload binary assets to CloudKit"
    )

    @Option(name: .shortAndLong, help: "CloudKit container identifier")
    var containerIdentifier: String = "iCloud.com.brightdigit.MistDemo"

    @Option(name: .shortAndLong, help: "CloudKit API token")
    var apiToken: String = ""

    @Option(name: .long, help: "Environment (development or production)")
    var environment: String = "development"

    @Argument(help: "Path to file to upload")
    var file: String

    @Option(name: .long, help: "Create record of this type with uploaded asset")
    var createRecord: String?

    func run() async throws {
        print("\n" + String(repeating: "=", count: 60))
        print("📤 Upload Asset to CloudKit")
        print(String(repeating: "=", count: 60))

        let resolvedToken = resolvedApiToken()

        guard !resolvedToken.isEmpty else {
            print("\n❌ Error: CloudKit API token is required")
            print("   Provide it via --api-token or set CLOUDKIT_API_TOKEN environment variable")
            print("   Get your API token from: https://icloud.developer.apple.com/dashboard/")
            return
        }

        let fileURL = URL(fileURLWithPath: file)

        guard FileManager.default.fileExists(atPath: file) else {
            print("\n❌ Error: File not found at path: \(file)")
            return
        }

        let tokenManager = APITokenManager(apiToken: resolvedToken)
        let service = try CloudKitService(
            containerIdentifier: containerIdentifier,
            tokenManager: tokenManager,
            environment: cloudKitEnvironment(),
            database: .public
        )

        do {
            let data = try Data(contentsOf: fileURL)
            let sizeInMB = Double(data.count) / 1024 / 1024
            print("\n📁 File: \(fileURL.lastPathComponent) (\(String(format: "%.2f", sizeInMB)) MB)")

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
            if let recordType = createRecord, let token = result.tokens.first {
                print("\n📝 Creating \(recordType) record with asset...")
                try await createRecordWithAsset(
                    service: service,
                    recordType: recordType,
                    filename: fileURL.lastPathComponent,
                    token: token,
                    fileSize: data.count
                )
            }

        } catch let error as CloudKitError {
            print("\n❌ CloudKit Error: \(error)")
            throw error
        } catch {
            print("\n❌ Error: \(error)")
            throw error
        }

        print("\n" + String(repeating: "=", count: 60))
        print("✅ Upload completed!")
        print(String(repeating: "=", count: 60))
    }

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
}
