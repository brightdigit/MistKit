//
//  MistKitClientTests.swift
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
@testable import MistKit
import Testing

@Suite("MistKitClient Tests")
struct MistKitClientTests {
  // MARK: - Configuration-Based Initialization Tests

  @Test("MistKitClient initializes with valid configuration and transport")
  func initWithConfiguration() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }

    let config = MistKitConfiguration(
      container: "iCloud.com.example.app",
      environment: .development,
      database: .public,
      apiToken: String(repeating: "a", count: 64)
    )

    let transport = MockTransport()
    _ = try MistKitClient(configuration: config, transport: transport)
  }

  @Test("MistKitClient initializes with API token configuration")
  func initWithAPIToken() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }

    let config = MistKitConfiguration(
      container: "iCloud.com.example.app",
      environment: .production,
      database: .public,
      apiToken: String(repeating: "f", count: 64)
    )

    let transport = MockTransport()
    _ = try MistKitClient(configuration: config, transport: transport)
  }

  // MARK: - Custom TokenManager Initialization Tests

  @Test("MistKitClient initializes with custom TokenManager")
  func initWithCustomTokenManager() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }

    let config = MistKitConfiguration(
      container: "iCloud.com.example.app",
      environment: .development,
      database: .public,
      apiToken: ""
    )

    let tokenManager = APITokenManager(apiToken: String(repeating: "b", count: 64))
    let transport = MockTransport()

    _ = try MistKitClient(
      configuration: config,
      tokenManager: tokenManager,
      transport: transport
    )
  }

  @Test("MistKitClient initializes with individual parameters")
  func initWithIndividualParameters() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }

    let tokenManager = APITokenManager(apiToken: String(repeating: "c", count: 64))
    let transport = MockTransport()

    _ = try MistKitClient(
      container: "iCloud.com.example.app",
      environment: .development,
      database: .public,
      tokenManager: tokenManager,
      transport: transport
    )
  }

  // MARK: - Server-to-Server Validation Tests

  @Test("MistKitClient allows ServerToServerAuthManager with public database")
  func serverToServerWithPublicDatabase() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }

    let privateKeyPEM = """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
    OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
    1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
    -----END PRIVATE KEY-----
    """

    let tokenManager = try ServerToServerAuthManager(
      keyID: String(repeating: "e", count: 64),
      pemString: privateKeyPEM
    )

    let config = MistKitConfiguration(
      container: "iCloud.com.example.app",
      environment: .development,
      database: .public,
      apiToken: ""
    )

    let transport = MockTransport()
    _ = try MistKitClient(
      configuration: config,
      tokenManager: tokenManager,
      transport: transport
    )
  }

  @Test("MistKitClient rejects ServerToServerAuthManager with private database")
  func serverToServerWithPrivateDatabase() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }

    let privateKeyPEM = """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
    OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
    1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
    -----END PRIVATE KEY-----
    """

    let tokenManager = try ServerToServerAuthManager(
      keyID: String(repeating: "f", count: 64),
      pemString: privateKeyPEM
    )

    let config = MistKitConfiguration(
      container: "iCloud.com.example.app",
      environment: .development,
      database: .private,
      apiToken: ""
    )

    let transport = MockTransport()

    do {
      _ = try MistKitClient(
        configuration: config,
        tokenManager: tokenManager,
        transport: transport
      )
      Issue.record("Expected TokenManagerError for server-to-server with private database")
    } catch let error as TokenManagerError {
      if case .invalidCredentials = error {
        // Success
      } else {
        Issue.record("Expected invalidCredentials error, got \(error)")
      }
    }
  }

  @Test("MistKitClient rejects ServerToServerAuthManager with shared database")
  func serverToServerWithSharedDatabase() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }

    let privateKeyPEM = """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
    OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
    1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
    -----END PRIVATE KEY-----
    """

    let tokenManager = try ServerToServerAuthManager(
      keyID: String(repeating: "0", count: 64),
      pemString: privateKeyPEM
    )

    let config = MistKitConfiguration(
      container: "iCloud.com.example.app",
      environment: .development,
      database: .shared,
      apiToken: ""
    )

    let transport = MockTransport()

    do {
      _ = try MistKitClient(
        configuration: config,
        tokenManager: tokenManager,
        transport: transport
      )
      Issue.record("Expected TokenManagerError for server-to-server with shared database")
    } catch let error as TokenManagerError {
      if case .invalidCredentials = error {
        // Success
      } else {
        Issue.record("Expected invalidCredentials error, got \(error)")
      }
    }
  }

  // MARK: - Environment and Database Tests

  @Test("MistKitClient supports all environments", arguments: [
    Environment.development,
    Environment.production
  ])
  func supportsAllEnvironments(environment: Environment) throws {
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

  @Test("MistKitClient supports all databases with API token", arguments: [
    Database.public,
    Database.private,
    Database.shared
  ])
  func supportsAllDatabases(database: Database) throws {
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
  func acceptsVariousContainerFormats() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }

    let containers = [
      "iCloud.com.example.app",
      "iCloud.com.example.MyApp",
      "iCloud.com.company.product"
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
