//
//  SyncCommand.swift
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
import BushelUtilities
import Foundation

internal enum SyncCommand {
  internal static func run(_ args: [String]) async throws {
    // Load configuration using Swift Configuration
    let loader = ConfigurationLoader()
    let rawConfig = try await loader.loadConfiguration()
    let config = try rawConfig.validated()

    // Enable verbose console output if requested
    BushelUtilities.ConsoleOutput.isVerbose = config.sync?.verbose ?? false

    // Build sync options from configuration
    let options = buildSyncOptions(from: config.sync)

    // Get fetch configuration (already loaded by ConfigurationLoader)
    let fetchConfiguration = config.fetch ?? FetchConfiguration.loadFromEnvironment()

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
      environment: config.cloudKit.environment,
      configuration: fetchConfiguration
    )

    // Execute sync
    do {
      let result = try await syncEngine.sync(options: options)

      // Write JSON to file if path specified
      if let outputFile = config.sync?.jsonOutputFile {
        let json = try result.toJSON(pretty: true)
        try json.write(toFile: outputFile, atomically: true, encoding: .utf8)
        BushelCloudKit.ConsoleOutput.info("✅ JSON output written to: \(outputFile)")
      }

      // Always show human-readable summary
      printSuccess(result)
    } catch {
      printError(error)
      Foundation.exit(1)
    }
  }

  // MARK: - Private Helpers

  private static func buildSyncOptions(from syncConfig: SyncConfiguration?)
    -> SyncEngine.SyncOptions
  {
    guard let syncConfig = syncConfig else {
      return SyncEngine.SyncOptions()
    }

    var pipelineOptions = DataSourcePipeline.Options()

    // Apply filters based on flags
    if syncConfig.restoreImagesOnly {
      pipelineOptions.includeXcodeVersions = false
      pipelineOptions.includeSwiftVersions = false
    } else if syncConfig.xcodeOnly {
      pipelineOptions.includeRestoreImages = false
      pipelineOptions.includeSwiftVersions = false
    } else if syncConfig.swiftOnly {
      pipelineOptions.includeRestoreImages = false
      pipelineOptions.includeXcodeVersions = false
    }

    if syncConfig.noBetas {
      pipelineOptions.includeBetaReleases = false
    }

    if syncConfig.noAppleWiki {
      pipelineOptions.includeTheAppleWiki = false
    }

    // Apply throttling options
    pipelineOptions.force = syncConfig.force
    pipelineOptions.specificSource = syncConfig.source

    return SyncEngine.SyncOptions(
      dryRun: syncConfig.dryRun,
      pipelineOptions: pipelineOptions
    )
  }

  private static func printSuccess(_ result: SyncEngine.DetailedSyncResult) {
    print("\n" + String(repeating: "=", count: 60))
    print("✅ Sync Summary")
    print(String(repeating: "=", count: 60))

    printTypeResult("RestoreImages", result.restoreImages)
    printTypeResult("XcodeVersions", result.xcodeVersions)
    printTypeResult("SwiftVersions", result.swiftVersions)

    let totalCreated = result.restoreImages.created + result.xcodeVersions.created + result.swiftVersions.created
    let totalUpdated = result.restoreImages.updated + result.xcodeVersions.updated + result.swiftVersions.updated
    let totalFailed = result.restoreImages.failed + result.xcodeVersions.failed + result.swiftVersions.failed

    print(String(repeating: "-", count: 60))
    print("TOTAL:")
    print("  ✨ Created: \(totalCreated)")
    print("  🔄 Updated: \(totalUpdated)")
    if totalFailed > 0 {
      print("  ❌ Failed:  \(totalFailed)")
    }
    print(String(repeating: "=", count: 60))
    print("\n💡 Next: Use 'bushel-cloud export' to view the synced data")
  }

  private static func printTypeResult(_ name: String, _ typeResult: SyncEngine.TypeSyncResult) {
    print("\n\(name):")
    print("  ✨ Created: \(typeResult.created)")
    print("  🔄 Updated: \(typeResult.updated)")
    if typeResult.failed > 0 {
      print("  ❌ Failed:  \(typeResult.failed)")
      if !typeResult.failedRecordNames.isEmpty {
        print("     Records: \(typeResult.failedRecordNames.prefix(5).joined(separator: ", "))")
        if typeResult.failedRecordNames.count > 5 {
          print("     ... and \(typeResult.failedRecordNames.count - 5) more")
        }
      }
    }
  }

  private static func printError(_ error: any Error) {
    print("\n❌ Sync failed: \(error.localizedDescription)")
    print("\n💡 Troubleshooting:")
    print("   • Verify your API token is valid")
    print("   • Check your internet connection")
    print("   • Ensure the CloudKit container exists")
    print("   • Verify external data sources are accessible")
  }
}
