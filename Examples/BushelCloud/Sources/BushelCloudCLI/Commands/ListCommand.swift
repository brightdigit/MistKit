//
//  ListCommand.swift
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

internal enum ListCommand {
  internal static func run(_ args: [String]) async throws {
    // Load configuration using Swift Configuration
    let loader = ConfigurationLoader()
    let rawConfig = try await loader.loadConfiguration()
    let config = try rawConfig.validated()

    // Create CloudKit service
    let cloudKitService: BushelCloudKitService
    if let pemString = config.cloudKit.privateKey {
      cloudKitService = try BushelCloudKitService(
        containerIdentifier: config.cloudKit.containerID,
        keyID: config.cloudKit.keyID,
        pemString: pemString,
        environment: config.cloudKit.environment
      )
    } else {
      cloudKitService = try BushelCloudKitService(
        containerIdentifier: config.cloudKit.containerID,
        keyID: config.cloudKit.keyID,
        privateKeyPath: config.cloudKit.privateKeyPath,
        environment: config.cloudKit.environment
      )
    }

    // Determine what to list based on flags
    let listConfig = config.list
    let listAll =
      !(listConfig?.restoreImages ?? false)
      && !(listConfig?.xcodeVersions ?? false)
      && !(listConfig?.swiftVersions ?? false)

    if listAll {
      try await cloudKitService.listAllRecords()
    } else {
      if listConfig?.restoreImages ?? false {
        try await cloudKitService.list(RestoreImageRecord.self)
      }
      if listConfig?.xcodeVersions ?? false {
        try await cloudKitService.list(XcodeVersionRecord.self)
      }
      if listConfig?.swiftVersions ?? false {
        try await cloudKitService.list(SwiftVersionRecord.self)
      }
    }
  }
}
