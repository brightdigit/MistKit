//
//  ExportCommand.swift
//  BushelCloud
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

import BushelCloudKit
import BushelFoundation
import Foundation
import MistKit

internal enum ExportCommand {
  // MARK: - Export Types

  private struct ExportData: Codable {
    let restoreImages: [RecordExport]
    let xcodeVersions: [RecordExport]
    let swiftVersions: [RecordExport]
  }

  private struct RecordExport: Codable {
    let recordName: String
    let recordType: String
    let fields: [String: String]

    init(from recordInfo: RecordInfo) {
      self.recordName = recordInfo.recordName
      self.recordType = recordInfo.recordType
      self.fields = recordInfo.fields.mapValues { fieldValue in
        String(describing: fieldValue)
      }
    }
  }

  private enum ExportError: Error {
    case encodingFailed
  }

  // MARK: - Command Implementation

  internal static func run(_ args: [String]) async throws {
    // Load configuration using Swift Configuration
    let loader = ConfigurationLoader()
    let rawConfig = try await loader.loadConfiguration()
    let config = try rawConfig.validated()

    // Enable verbose console output if requested
    ConsoleOutput.isVerbose = config.export?.verbose ?? false

    // Determine authentication method
    let authMethod: CloudKitAuthMethod
    if let pemString = config.cloudKit.privateKey {
      authMethod = .pemString(pemString)
    } else {
      authMethod = .pemFile(path: config.cloudKit.privateKeyPath)
    }

    // Create sync engine
    let syncEngine = try SyncEngine(
      containerIdentifier: config.cloudKit.containerID,
      keyID: config.cloudKit.keyID,
      authMethod: authMethod,
      environment: config.cloudKit.environment
    )

    // Execute export
    do {
      let result = try await syncEngine.export()
      let filtered = applyFilters(to: result, with: config.export)
      let json = try encodeToJSON(filtered, pretty: config.export?.pretty ?? false)

      if let outputPath = config.export?.output {
        try writeToFile(json, at: outputPath)
        print("✅ Exported to: \(outputPath)")
      } else {
        print(json)
      }
    } catch {
      printError(error)
      Foundation.exit(1)
    }
  }

  // MARK: - Private Helpers

  private static func applyFilters(
    to result: SyncEngine.ExportResult,
    with exportConfig: ExportConfiguration?
  ) -> SyncEngine.ExportResult {
    guard let exportConfig = exportConfig else {
      return result
    }

    var restoreImages = result.restoreImages
    var xcodeVersions = result.xcodeVersions
    var swiftVersions = result.swiftVersions

    // Filter signed-only restore images
    if exportConfig.signedOnly {
      restoreImages = restoreImages.filter { record in
        if case .int64(let isSigned) = record.fields["isSigned"] {
          return isSigned != 0
        }
        return false
      }
    }

    // Filter out betas
    if exportConfig.noBetas {
      restoreImages = restoreImages.filter { record in
        if case .int64(let isPrerelease) = record.fields["isPrerelease"] {
          return isPrerelease == 0
        }
        return true
      }

      xcodeVersions = xcodeVersions.filter { record in
        if case .int64(let isPrerelease) = record.fields["isPrerelease"] {
          return isPrerelease == 0
        }
        return true
      }

      swiftVersions = swiftVersions.filter { record in
        if case .int64(let isPrerelease) = record.fields["isPrerelease"] {
          return isPrerelease == 0
        }
        return true
      }
    }

    return SyncEngine.ExportResult(
      restoreImages: restoreImages,
      xcodeVersions: xcodeVersions,
      swiftVersions: swiftVersions
    )
  }

  private static func encodeToJSON(_ result: SyncEngine.ExportResult, pretty: Bool) throws
    -> String
  {
    let export = ExportData(
      restoreImages: result.restoreImages.map(RecordExport.init),
      xcodeVersions: result.xcodeVersions.map(RecordExport.init),
      swiftVersions: result.swiftVersions.map(RecordExport.init)
    )

    let encoder = JSONEncoder()
    if pretty {
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    let data = try encoder.encode(export)
    guard let json = String(data: data, encoding: .utf8) else {
      throw ExportError.encodingFailed
    }

    return json
  }

  private static func writeToFile(_ content: String, at path: String) throws {
    try content.write(toFile: path, atomically: true, encoding: .utf8)
  }

  private static func printError(_ error: any Error) {
    print("\n❌ Export failed: \(error.localizedDescription)")
    print("\n💡 Troubleshooting:")
    print("   • Verify your API token is valid")
    print("   • Check your internet connection")
    print("   • Ensure data has been synced to CloudKit")
    print("   • Run 'bushel-cloud sync' first if needed")
  }
}
