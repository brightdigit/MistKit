//
//  DemoCommand.swift
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
import Hummingbird
import Logging
import MistKit

#if canImport(AppKit)
import AppKit
#endif

/// Interactive CloudKit authentication demo command
struct DemoCommand: MistDemoCommand {
  // MARK: Lifecycle

  init() {}

  // MARK: Public

  static let configuration = CommandConfiguration(
    commandName: "demo",
    abstract: "Run the interactive CloudKit authentication demo",
    discussion: """
      This command demonstrates CloudKit authentication methods including:
      - Interactive Sign in with Apple ID
      - API-only authentication
      - Server-to-server authentication
      - Token management and validation
      """
  )

  @OptionGroup var globalOptions: GlobalOptions

  @Option(name: .long, help: "Server host")
  var host: String = "127.0.0.1"

  @Option(name: .long, help: "Server port")
  var port: Int = 8080

  @Flag(name: .long, help: "Skip authentication and use provided token")
  var skipAuth: Bool = false

  @Flag(name: .long, help: "Test all authentication methods")
  var testAllAuth: Bool = false

  @Flag(name: .long, help: "Test API-only authentication")
  var testApiOnly: Bool = false

  @Flag(name: .long, help: "Test adaptive token manager")
  var testAdaptive: Bool = false

  @Flag(name: .long, help: "Test server-to-server authentication")
  var testServerToServer: Bool = false

  func execute(with config: MistDemoConfig) async throws {
    // Get resolved API token
    let resolvedApiToken = config.resolvedApiToken()

    guard !resolvedApiToken.isEmpty else {
      print("❌ Error: CloudKit API token is required")
      print("   Provide it via --api-token or set CLOUDKIT_API_TOKEN environment variable")
      print("   Get your API token from: https://icloud.developer.apple.com/dashboard/")
      print("\n💡 Environment variables available:")
      let maskedEnv = EnvironmentConfig.CloudKit.getMaskedEnvironment()
      for (key, value) in maskedEnv.sorted(by: { $0.key < $1.key }) {
        print("   \(key): \(value)")
      }
      return
    }

    let effectiveApiToken = resolvedApiToken

    if testAllAuth {
      try await testAllAuthenticationMethods(
        apiToken: effectiveApiToken,
        containerIdentifier: config.containerIdentifier,
        webAuthToken: config.resolvedWebAuthToken(),
        environment: config.environment
      )
    } else if testApiOnly {
      try await testAPIOnlyAuthentication(
        apiToken: effectiveApiToken,
        containerIdentifier: config.containerIdentifier,
        environment: config.environment
      )
    } else if testAdaptive {
      try await testAdaptiveTokenManager(
        apiToken: effectiveApiToken,
        webAuthToken: config.resolvedWebAuthToken()
      )
    } else if testServerToServer {
      try await testServerToServerAuthentication(
        apiToken: effectiveApiToken,
        containerIdentifier: config.containerIdentifier,
        keyID: config.keyID,
        privateKey: config.privateKey,
        privateKeyFile: config.privateKeyFile,
        environment: config.environment
      )
    } else if skipAuth, let token = config.resolvedWebAuthToken() {
      try await runCloudKitDemo(
        webAuthToken: token,
        apiToken: effectiveApiToken,
        containerIdentifier: config.containerIdentifier
      )
    } else {
      try await startAuthenticationServer(
        apiToken: effectiveApiToken,
        containerIdentifier: config.containerIdentifier,
        host: host,
        port: port
      )
    }
  }

  // MARK: Private

  private func startAuthenticationServer(
    apiToken: String,
    containerIdentifier: String,
    host: String,
    port: Int
  ) async throws {
    print("\n" + String(repeating: "=", count: 60))
    print("🚀 MistKit CloudKit Authentication Server")
    print(String(repeating: "=", count: 60))
    print("\n📍 Server URL: http://\(host):\(port)")
    print("📱 Container: \(containerIdentifier)")
    print("🔑 API Token: \(apiToken.maskedAPIToken)")
    print("\n" + String(repeating: "-", count: 60))
    print("📋 Instructions:")
    print("1. Opening browser to: http://\(host):\(port)")
    print("2. Click 'Sign In with Apple ID'")
    print("3. Authenticate with your Apple ID")
    print("4. The demo will run automatically after authentication")
    print(String(repeating: "-", count: 60))
    print("\n⚠️  IMPORTANT: Update these values in index.html before authenticating:")
    print("   • containerIdentifier: '\(containerIdentifier)'")
    print("   • apiToken: 'YOUR_VALID_API_TOKEN' (get from CloudKit Console)")
    print("   • Ensure container exists and API token is valid")
    print(String(repeating: "=", count: 60) + "\n")

    let tokenChannel = AsyncChannel<String>()
    let responseCompleteChannel = AsyncChannel<Void>()

    let router = Router(context: BasicRequestContext.self)
    router.middlewares.add(LogRequestsMiddleware(.info))

    let possiblePaths = [
      Bundle.main.resourcePath ?? "",
      Bundle.main.bundlePath + "/Contents/Resources",
      "./Sources/MistDemo/Resources",
      "./Examples/Sources/MistDemo/Resources",
      URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Resources").path
    ]

    var resourcesPath = "./Sources/MistDemo/Resources"
    for path in possiblePaths {
      if !path.isEmpty && FileManager.default.fileExists(atPath: path + "/index.html") {
        resourcesPath = path
        break
      }
    }

    print("📁 Serving static files from: \(resourcesPath)")
    router.middlewares.add(
      FileMiddleware(
        resourcesPath,
        searchForIndexHtml: true
      )
    )

    let api = router.group("api")
    api.post("authenticate") { request, context -> Response in
      let authRequest = try await request.decode(as: AuthRequest.self, context: context)
      await tokenChannel.send(authRequest.sessionToken)

      let webAuthToken = authRequest.sessionToken
      var userData: UserInfo?
      var zones: [ZoneInfo] = []
      var errorMessage: String?

      do {
        let service = try CloudKitService(
          containerIdentifier: containerIdentifier,
          apiToken: apiToken,
          webAuthToken: webAuthToken
        )
        userData = try await service.fetchCurrentUser()
        zones = try await service.listZones()
      } catch {
        errorMessage = error.localizedDescription
        print("CloudKit error: \(error)")
      }

      let response = AuthResponse(
        userRecordName: authRequest.userRecordName,
        cloudKitData: .init(
          user: userData,
          zones: zones,
          error: errorMessage
        ),
        message: "Authentication successful! The demo will start automatically..."
      )

      let jsonData = try JSONEncoder().encode(response)

      Task {
        try await Task.sleep(nanoseconds: 200_000_000)
        await responseCompleteChannel.send(())
      }

      return Response(
        status: .ok,
        headers: [.contentType: "application/json"],
        body: ResponseBody { writer in
          try await writer.write(ByteBuffer(bytes: jsonData))
          try await writer.finish(nil)
        }
      )
    }

    let app = Application(
      router: router,
      configuration: .init(
        address: .hostname(host, port: port)
      )
    )

    let serverTask = Task {
      try await app.runService()
    }

    Task {
      try await Task.sleep(nanoseconds: 1_000_000_000)
      print("🌐 Opening browser...")
      BrowserOpener.openBrowser(url: "http://\(host):\(port)")
    }

    print("\n⏳ Waiting for authentication...")
    let token = await tokenChannel.receive()

    print("\n✅ Authentication successful! Received session token.")
    print("⏳ Waiting for response to complete...")

    await responseCompleteChannel.receive()

    print("🔄 Shutting down server...")
    serverTask.cancel()

    try await Task.sleep(nanoseconds: 500_000_000)

    print("\n📱 Starting CloudKit demo...\n")
    try await runCloudKitDemo(
      webAuthToken: token,
      apiToken: apiToken,
      containerIdentifier: containerIdentifier
    )
  }

  private func runCloudKitDemo(
    webAuthToken: String,
    apiToken: String,
    containerIdentifier: String
  ) async throws {
    print(String(repeating: "=", count: 50))
    print("🌩️  MistKit CloudKit Demo")
    print(String(repeating: "=", count: 50))
    print("Container: \(containerIdentifier)")
    print("Environment: development")
    print(String(repeating: "-", count: 50))

    let cloudKitService = try CloudKitService(
      containerIdentifier: containerIdentifier,
      apiToken: apiToken,
      webAuthToken: webAuthToken
    )

    print("\n👤 Fetching current user...")
    do {
      let userInfo = try await cloudKitService.fetchCurrentUser()
      print("✅ User Record Name: \(userInfo.userRecordName)")
      if let firstName = userInfo.firstName {
        print("   First Name: \(firstName)")
      }
      if let lastName = userInfo.lastName {
        print("   Last Name: \(lastName)")
      }
      if let email = userInfo.emailAddress {
        print("   Email: \(email)")
      }
    } catch {
      print("❌ Failed to fetch user: \(error)")
    }

    print("\n📁 Listing zones...")
    do {
      let zones = try await cloudKitService.listZones()
      print("✅ Found \(zones.count) zone(s):")
      for zone in zones {
        print("   • \(zone.zoneName)")
      }
    } catch {
      print("❌ Failed to list zones: \(error)")
    }

    print("\n📋 Querying records...")
    do {
      let records = try await cloudKitService.queryRecords(recordType: "TodoItem", limit: 5)
      if !records.isEmpty {
        print("✅ Found \(records.count) record(s)")
        for record in records.prefix(3) {
          print("\n   Record: \(record.recordName)")
          print("   Type: \(record.recordType)")
          print("   Fields: \(FieldValueFormatter.formatFields(record.fields))")
        }
      } else {
        print("ℹ️  No records found in the _defaultZone")
        print("   You may need to create some test records first")
      }
    } catch {
      print("❌ Failed to query records: \(error)")
    }

    print("\n" + String(repeating: "=", count: 50))
    print("✅ Demo completed!")
    print(String(repeating: "=", count: 50))

    print("\n💡 Tip: You can skip authentication next time by running:")
    print("   mistdemo --skip-auth --web-auth-token \"\(webAuthToken)\"")
  }

  private func testAllAuthenticationMethods(
    apiToken: String,
    containerIdentifier: String,
    webAuthToken: String?,
    environment: MistKit.Environment
  ) async throws {
    print("\n" + String(repeating: "=", count: 70))
    print("🧪 MistKit Authentication Methods Test Suite")
    print(String(repeating: "=", count: 70))
    print("Container: \(containerIdentifier)")
    print("API Token: \(apiToken.maskedAPIToken)")
    print(String(repeating: "=", count: 70))

    print("\n🔐 Test 1: API-only Authentication (Public Database)")
    print(String(repeating: "-", count: 50))
    do {
      let apiTokenManager = APITokenManager(apiToken: apiToken)
      let service = try CloudKitService(
        containerIdentifier: containerIdentifier,
        tokenManager: apiTokenManager,
        environment: environment,
        database: .public
      )

      print("📋 Validating API token credentials...")
      let isValid = try await apiTokenManager.validateCredentials()
      print("✅ API Token validation: \(isValid ? "PASSED" : "FAILED")")

      print("📁 Listing public zones...")
      let zones = try await service.listZones()
      print("✅ Found \(zones.count) public zone(s)")
    } catch {
      print("❌ API-only authentication test failed: \(error)")
    }

    print("\n🌐 Test 2: Web Authentication (Private Database)")
    print(String(repeating: "-", count: 50))
    if let webToken = webAuthToken {
      do {
        let webTokenManager = WebAuthTokenManager(apiToken: apiToken, webAuthToken: webToken)
        let service = try CloudKitService(
          containerIdentifier: containerIdentifier,
          tokenManager: webTokenManager,
          environment: environment,
          database: .private
        )

        print("📋 Validating web auth credentials...")
        let isValid = try await webTokenManager.validateCredentials()
        print("✅ Web Auth validation: \(isValid ? "PASSED" : "FAILED")")

        print("👤 Fetching current user...")
        let userInfo = try await service.fetchCurrentUser()
        print("✅ User: \(userInfo.userRecordName)")

        print("📁 Listing private zones...")
        let zones = try await service.listZones()
        print("✅ Found \(zones.count) private zone(s)")
      } catch {
        print("❌ Web authentication test failed: \(error)")
      }
    } else {
      print("⚠️  Skipped: No web auth token provided")
      print("   Use --web-auth-token <token> to test web authentication")
    }

    print("\n🔄 Test 3: AdaptiveTokenManager Transitions")
    print(String(repeating: "-", count: 50))
    await testAdaptiveTokenManagerInternal(apiToken: apiToken, webAuthToken: webAuthToken)

    print("\n🔐 Test 4: Server-to-Server Authentication (Test Keys)")
    print(String(repeating: "-", count: 50))
    print("⚠️  Server-to-server authentication requires real keys from Apple Developer Console")
    print("   Use --test-server-to-server with --key-id and --private-key-file for testing")

    print("\n" + String(repeating: "=", count: 70))
    print("✅ Authentication test suite completed!")
    print(String(repeating: "=", count: 70))
  }

  private func testAPIOnlyAuthentication(
    apiToken: String,
    containerIdentifier: String,
    environment: MistKit.Environment
  ) async throws {
    print("\n" + String(repeating: "=", count: 60))
    print("🔐 API-only Authentication Test")
    print(String(repeating: "=", count: 60))
    print("Container: \(containerIdentifier)")
    print("Database: public (API-only limitation)")
    print(String(repeating: "-", count: 60))

    do {
      let tokenManager = APITokenManager(apiToken: apiToken)
      let service = try CloudKitService(
        containerIdentifier: containerIdentifier,
        tokenManager: tokenManager,
        environment: environment,
        database: .public
      )

      print("\n📋 Testing API-only authentication...")
      print("✅ CloudKitService initialized with API-only authentication")

      print("\n📁 Listing zones in public database...")
      let zones = try await service.listZones()
      print("✅ Found \(zones.count) zone(s):")
      for zone in zones {
        print("   • \(zone.zoneName)")
      }

      print("\n📋 Querying records from public database...")
      let records = try await service.queryRecords(recordType: "TodoItem", limit: 5)
      print("✅ Found \(records.count) record(s) in public database")
      for record in records.prefix(3) {
        print("   Record: \(record.recordName)")
        print("     Type: \(record.recordType)")
        print("     Fields: \(FieldValueFormatter.formatFields(record.fields))")
      }
    } catch {
      print("❌ API-only authentication test failed: \(error)")
    }

    print("\n" + String(repeating: "=", count: 60))
    print("✅ API-only authentication test completed!")
    print(String(repeating: "=", count: 60))
  }

  private func testAdaptiveTokenManager(
    apiToken: String,
    webAuthToken: String?
  ) async throws {
    print("\n" + String(repeating: "=", count: 60))
    print("🔄 AdaptiveTokenManager Transition Test")
    print(String(repeating: "=", count: 60))
    await testAdaptiveTokenManagerInternal(apiToken: apiToken, webAuthToken: webAuthToken)
    print(String(repeating: "=", count: 60))
    print("✅ AdaptiveTokenManager test completed!")
    print(String(repeating: "=", count: 60))
  }

  private func testAdaptiveTokenManagerInternal(
    apiToken: String,
    webAuthToken: String?
  ) async {
    do {
      print("📋 Creating AdaptiveTokenManager with API token...")
      let adaptiveManager = AdaptiveTokenManager(apiToken: apiToken)

      print("🔍 Testing initial API-only state...")
      let initialCredentials = try await adaptiveManager.getCurrentCredentials()
      if case let .apiToken(token) = initialCredentials?.method {
        print("✅ Initial state: API-only authentication (\(String(token.prefix(8)))...)")
      }

      let hasCredentials = await adaptiveManager.hasCredentials
      print("✅ Has credentials: \(hasCredentials)")

      print("🔍 Testing credential validation...")
      let isValid = try await adaptiveManager.validateCredentials()
      print("✅ Credential validation: \(isValid ? "PASSED" : "FAILED")")

      if let webToken = webAuthToken {
        print("🔄 Testing upgrade to web authentication...")
        let upgradedCredentials = try await adaptiveManager.upgradeToWebAuthentication(webAuthToken: webToken)
        if case let .webAuthToken(api, web) = upgradedCredentials.method {
          print("✅ Upgraded to web auth (API: \(String(api.prefix(8)))..., Web: \(String(web.prefix(8)))...)")
        }

        let validAfterUpgrade = try await adaptiveManager.validateCredentials()
        print("✅ Validation after upgrade: \(validAfterUpgrade ? "PASSED" : "FAILED")")

        print("🔄 Testing downgrade to API-only...")
        let downgradedCredentials = try await adaptiveManager.downgradeToAPIOnly()
        if case let .apiToken(token) = downgradedCredentials.method {
          print("✅ Downgraded to API-only (\(String(token.prefix(8)))...)")
        }

        print("✅ AdaptiveTokenManager transitions completed successfully!")
      } else {
        print("⚠️  Transition test skipped: No web auth token provided")
        print("   Use --web-auth-token <token> to test full transition functionality")
      }
    } catch {
      print("❌ AdaptiveTokenManager test failed: \(error)")
    }
  }

  private func testServerToServerAuthentication(
    apiToken: String,
    containerIdentifier: String,
    keyID: String?,
    privateKey: String?,
    privateKeyFile: String?,
    environment: MistKit.Environment
  ) async throws {
    print("\n" + String(repeating: "=", count: 60))
    print("🔐 Server-to-Server Authentication Test")
    print(String(repeating: "=", count: 60))
    print("Container: \(containerIdentifier)")
    print("Database: public (server-to-server only supports public database)")
    print("ℹ️  Note: Server-to-server keys must be registered in CloudKit Dashboard")
    print("ℹ️  See: https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html")
    print(String(repeating: "-", count: 60))

    let privateKeyPEM: String
    var keyIdentifier: String = ""

    if let keyFile = privateKeyFile {
      print("📁 Reading private key from file: \(keyFile)")
      do {
        privateKeyPEM = try String(contentsOfFile: keyFile, encoding: .utf8)
        print("✅ Private key loaded from file")
      } catch {
        print("❌ Failed to read private key file: \(error)")
        print("💡 Make sure the file exists and is readable")
        return
      }
    } else if let key = privateKey {
      privateKeyPEM = key
      print("🔑 Using provided private key")
    } else {
      print("❌ No private key provided for server-to-server authentication")
      print("💡 Please provide a key using one of these options:")
      print("   --private-key-file 'path/to/private_key.pem'")
      print("   --private-key 'PEM_STRING'")
      print("   --key-id 'your_key_id'")
      print("")
      print("🔗 For more information:")
      print("   https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html")
      return
    }

    if let providedKeyID = keyID {
      keyIdentifier = providedKeyID
      print("🔑 Using provided key ID: \(keyIdentifier)")
    } else {
      print("❌ Key ID is required for server-to-server authentication")
      print("💡 Use --key-id 'your_key_id' to specify the key ID")
      return
    }

    do {
      if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
        print("\n📋 Creating ServerToServerAuthManager...")
        let serverManager = try ServerToServerAuthManager(
          keyID: keyIdentifier,
          pemString: privateKeyPEM
        )

        print("🔍 Testing server-to-server credentials...")
        let isValid = try await serverManager.validateCredentials()
        print("✅ Credential validation: \(isValid ? "PASSED" : "FAILED")")

        print("\n🌐 Testing CloudKit integration...")
        let service = try CloudKitService(
          containerIdentifier: containerIdentifier,
          tokenManager: serverManager,
          environment: environment,
          database: .public
        )

        print("✅ CloudKitService initialized with server-to-server authentication (public database only)")

        print("\n📋 Querying public records with server-to-server authentication...")
        let records = try await service.queryRecords(recordType: "TodoItem", limit: 5)
        print("✅ Found \(records.count) public record(s):")
        for record in records.prefix(3) {
          print("   • Record: \(record.recordName)")
          print("     Type: \(record.recordType)")
          print("     Fields: \(FieldValueFormatter.formatFields(record.fields))")
        }
      } else {
        print("❌ Server-to-server authentication requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+")
        print("💡 On older platforms, use API-only or Web authentication instead")
      }
    } catch {
      print("❌ Server-to-server authentication test failed: \(error)")

      print("💡 Server-to-server setup checklist (per Apple docs):")
      print("   1. Create server-to-server certificate with OpenSSL")
      print("   2. Extract public key from certificate")
      print("   3. Register public key in CloudKit Dashboard")
      print("   4. Obtain key ID from CloudKit Dashboard")
      print("   5. Ensure container has server-to-server access enabled")
      print("   6. Verify key is enabled and not expired")
      print("   7. Only public database access is supported")
      print("📖 Full setup guide:")
      print("   https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html")
    }

    print("\n" + String(repeating: "=", count: 60))
    print("✅ Server-to-server authentication test completed!")
    print(String(repeating: "=", count: 60))

    if keyID == nil && privateKey == nil && privateKeyFile == nil {
      print("\n💡 To test with real CloudKit server-to-server authentication:")
      print("   1. Generate a key pair in Apple Developer Console")
      print("   2. Run: mistdemo --test-server-to-server \\")
      print("             --key-id 'your_key_id' \\")
      print("             --private-key-file 'path/to/private_key.pem'")
    }
  }
}
