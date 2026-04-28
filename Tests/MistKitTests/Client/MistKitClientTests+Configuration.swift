//
//  MistKitClientTests+Configuration.swift
//  MistKit
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
import Testing

@testable import MistKit

extension MistKitClientTests {
  // MARK: - Environment and Database Tests

  @Test(
    "MistKitClient supports all environments",
    arguments: [
      Environment.development,
      Environment.production,
    ]
  )
  internal func supportsAllEnvironments(
    environment: Environment
  ) throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }

    let config = MistKitConfiguration(
      container: "iCloud.com.example.app",
      environment: environment,
      database: .public,
      apiToken: String(repeating: "3", count: 64)
    )

    let transport = MockTransport()
    _ = try MistKitClient(configuration: config, transport: transport)
  }

  @Test(
    "MistKitClient supports all databases with API token",
    arguments: [
      Database.public,
      Database.private,
      Database.shared,
    ]
  )
  internal func supportsAllDatabases(database: Database) throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }

    let config = MistKitConfiguration(
      container: "iCloud.com.example.app",
      environment: .development,
      database: database,
      apiToken: String(repeating: "4", count: 64)
    )

    let transport = MockTransport()
    _ = try MistKitClient(configuration: config, transport: transport)
  }

  // MARK: - Container Identifier Tests

  @Test("MistKitClient accepts various container formats")
  internal func acceptsVariousContainerFormats() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }

    let containers = [
      "iCloud.com.example.app",
      "iCloud.com.example.MyApp",
      "iCloud.com.company.product",
    ]

    for container in containers {
      let config = MistKitConfiguration(
        container: container,
        environment: .development,
        database: .public,
        apiToken: String(repeating: "5", count: 64)
      )

      let transport = MockTransport()
      _ = try MistKitClient(configuration: config, transport: transport)
    }
  }
}
