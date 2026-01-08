//
//  ClearCommand.swift
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

internal enum ClearCommand {
  internal static func run(_ args: [String]) async throws {
    // Load configuration using Swift Configuration
    let loader = ConfigurationLoader()
    let rawConfig = try await loader.loadConfiguration()
    let config = try rawConfig.validated()

    // Enable verbose console output if requested
    BushelUtilities.ConsoleOutput.isVerbose = config.clear?.verbose ?? false

    // Confirm deletion unless --yes flag is provided
    let skipConfirmation = config.clear?.yes ?? false
    if !skipConfirmation {
      print("\n⚠️  WARNING: This will delete ALL records from CloudKit!")
      print("   Container: \(config.cloudKit.containerID)")
      print("   Database: public (development)")
      print("")
      print("   This operation cannot be undone.")
      print("")
      print("   Type 'yes' to confirm: ", terminator: "")

      guard let response = readLine(), response.lowercased() == "yes" else {
        print("\n❌ Operation cancelled")
        Foundation.exit(1)
      }
    }

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

    // Execute clear
    do {
      try await syncEngine.clear()
      print("\n✅ All records have been deleted from CloudKit")
    } catch {
      printError(error)
      Foundation.exit(1)
    }
  }

  // MARK: - Private Helpers

  private static func printError(_ error: any Error) {
    print("\n❌ Clear failed: \(error.localizedDescription)")
    print("\n💡 Troubleshooting:")
    print("   • Verify your API token is valid")
    print("   • Check your internet connection")
    print("   • Ensure the CloudKit container exists")
  }
}
