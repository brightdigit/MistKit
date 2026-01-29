//
//  MistDemo.swift
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
import Hummingbird
import Logging
import MistKit
import UnixSignals

#if canImport(AppKit)
import AppKit
#endif

@main
struct MistDemo {
  @MainActor
  static func main() async throws {
    // Register available commands
    CommandRegistry.register(AuthTokenCommand.self)
    CommandRegistry.register(CurrentUserCommand.self)
    CommandRegistry.register(QueryCommand.self)
    CommandRegistry.register(CreateCommand.self)
    
    // Parse command line arguments
    let parser = CommandLineParser()
    
    // Check for help
    if parser.isHelpRequested() {
      printHelp(commandName: parser.parseCommandName())
      return
    }
    
    // Check if a command was specified
    if let commandName = parser.parseCommandName() {
      // Execute specific command
      try await executeCommand(commandName)
    } else {
      // Fall back to legacy behavior for backward compatibility
      try await executeLegacyMode()
    }
  }
  
  /// Execute a specific command
  private static func executeCommand(_ commandName: String) async throws {
    switch commandName {
    case "auth-token":
      let command = try AuthTokenCommand()
      try await command.execute()
    case "current-user":
      let command = try CurrentUserCommand()
      try await command.execute()
    case "query":
      let command = try QueryCommand()
      try await command.execute()
    case "create":
      let command = try CreateCommand()
      try await command.execute()
    default:
      print("❌ Unknown command: \(commandName)")
      print("Available commands: \(await CommandRegistry.availableCommands.joined(separator: ", "))")
      print("Run 'mistdemo help' for usage information.")
      throw MistDemoError.unknownCommand(commandName)
    }
  }
  
  /// Print help information
  private static func printHelp(commandName: String? = nil) {
    if let commandName = commandName {
      printCommandHelp(commandName)
    } else {
      printGeneralHelp()
    }
  }
  
  /// Print general help
  private static func printGeneralHelp() {
    print("MistDemo - CloudKit Web Services Command Line Tool")
    print("")
    print("USAGE:")
    print("    mistdemo <command> [options]")
    print("")
    print("COMMANDS:")
    print("    auth-token    Obtain a web authentication token via browser flow")
    print("    current-user  Get current user information")
    print("    query         Query records from CloudKit with filtering and sorting")
    print("    create        Create a new record in CloudKit")
    print("")
    print("OPTIONS:")
    print("    --help, -h    Show help information")
    print("")
    print("Run 'mistdemo <command> --help' for command-specific help.")
    print("")
    print("LEGACY MODE:")
    print("    Running without a command starts the legacy authentication server.")
  }
  
  /// Print command-specific help
  private static func printCommandHelp(_ commandName: String) {
    switch commandName {
    case "auth-token":
      print("AUTH-TOKEN - Obtain web authentication token")
      print("")
      print("USAGE:")
      print("    mistdemo auth-token [options]")
      print("")
      print("OPTIONS:")
      print("    --api-token <token>     CloudKit API token (or CLOUDKIT_API_TOKEN env)")
      print("    --port <port>           Server port (default: 8080)")
      print("    --host <host>           Server host (default: 127.0.0.1)")
      print("    --no-browser           Don't open browser automatically")
      
    case "current-user":
      print("CURRENT-USER - Get current user information")
      print("")
      print("USAGE:")
      print("    mistdemo current-user [options]")
      print("")
      print("OPTIONS:")
      print("    --api-token <token>        CloudKit API token")
      print("    --web-auth-token <token>   Web authentication token")
      print("    --fields <fields>          Comma-separated list of fields to include")
      print("    --output-format <format>   Output format: json, table, csv, yaml")
      
    case "query":
      print("QUERY - Query records from CloudKit")
      print("")
      print("USAGE:")
      print("    mistdemo query [options]")
      print("")
      print("OPTIONS:")
      print("    --record-type <type>       Record type to query (default: Note)")
      print("    --zone <zone>              Zone name (default: _defaultZone)")
      print("    --filter <filter>          Filter expression (field:operator:value)")
      print("    --sort <field:order>       Sort by field (order: asc/desc)")
      print("    --limit <count>            Maximum records to return (1-200)")
      print("    --fields <fields>          Comma-separated fields to include")
      print("    --output-format <format>   Output format: json, table, csv, yaml")
      
    case "create":
      print("CREATE - Create a new record in CloudKit")
      print("")
      print("USAGE:")
      print("    mistdemo create [options]")
      print("")
      print("REQUIRED:")
      print("    --api-token <token>            CloudKit API token")
      print("    --web-auth-token <token>       Web authentication token")
      print("")
      print("OPTIONS:")
      print("    --record-type <type>           Record type to create (default: Note)")
      print("    --zone <zone>                  Zone name (default: _defaultZone)")
      print("    --record-name <name>           Custom record name (auto-generated if omitted)")
      print("    --output-format <format>       Output format: json, table, csv, yaml")
      print("")
      print("FIELD DEFINITION (choose one method):")
      print("    --field <name:type:value>      Inline field definition")
      print("    --json-file <file>             Load fields from JSON file")
      print("    --stdin                        Read fields from stdin as JSON")
      print("")
      print("FIELD FORMAT:")
      print("    Format: name:type:value")
      print("    Multiple fields: separate with commas")
      print("")
      print("FIELD TYPES:")
      print("    string      Text values")
      print("    int64       Integer numbers")
      print("    double      Decimal numbers")
      print("    timestamp   Dates (ISO 8601 or Unix timestamp)")
      print("")
      print("EXAMPLES:")
      print("")
      print("  1. Single field:")
      print("     mistdemo create --field \"title:string:My Note\"")
      print("")
      print("  2. Multiple fields (comma-separated):")
      print("     mistdemo create --field \"title:string:My Note, priority:int64:5\"")
      print("")
      print("  3. With timestamp:")
      print("     mistdemo create --field \"title:string:Task, due:timestamp:2026-02-01T09:00:00Z\"")
      print("")
      print("  4. From JSON file:")
      print("     mistdemo create --json-file fields.json")
      print("")
      print("     Example fields.json:")
      print("     {")
      print("       \"title\": \"Project Plan\",")
      print("       \"priority\": 8,")
      print("       \"progress\": 0.35")
      print("     }")
      print("")
      print("  5. From stdin:")
      print("     echo '{\"title\":\"Quick Note\"}' | mistdemo create --stdin")
      print("")
      print("  6. Table output format:")
      print("     mistdemo create --field \"title:string:Test\" --output-format table")
      print("")
      print("NOTES:")
      print("  • Record name is auto-generated if not provided")
      print("  • JSON files auto-detect field types from values")
      print("  • Use environment variables CLOUDKIT_API_TOKEN and CLOUDKIT_WEBAUTH_TOKEN")
      print("    to avoid repeating tokens")
      
    default:
      print("Unknown command: \(commandName)")
      printGeneralHelp()
    }
  }
  
  /// Execute legacy mode for backward compatibility
  private static func executeLegacyMode() async throws {
    // Load configuration using Swift Configuration
    let config = try MistDemoConfig()

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

    if config.testAllAuth {
      try await testAllAuthenticationMethods(
        apiToken: effectiveApiToken,
        containerIdentifier: config.containerIdentifier,
        webAuthToken: config.resolvedWebAuthToken(),
        environment: config.environment
      )
    } else if config.testApiOnly {
      try await testAPIOnlyAuthentication(
        apiToken: effectiveApiToken,
        containerIdentifier: config.containerIdentifier,
        environment: config.environment
      )
    } else if config.testAdaptive {
      try await testAdaptiveTokenManager(
        apiToken: effectiveApiToken,
        webAuthToken: config.resolvedWebAuthToken()
      )
    } else if config.testServerToServer {
      try await testServerToServerAuthentication(
        apiToken: effectiveApiToken,
        containerIdentifier: config.containerIdentifier,
        keyID: config.keyID,
        privateKey: config.privateKey,
        privateKeyFile: config.privateKeyFile,
        environment: config.environment
      )
    } else if let token = config.resolvedWebAuthToken(), !token.isEmpty {
      // Auto-detect: Web auth token provided → skip auth server
      if config.skipAuth {
        print("⚠️  Warning: --skip-auth is deprecated. Token presence is now auto-detected.")
      }
      try await runCloudKitDemo(
        webAuthToken: token,
        apiToken: effectiveApiToken,
        containerIdentifier: config.containerIdentifier
      )
    } else {
      try await startAuthenticationServer(
        apiToken: effectiveApiToken,
        containerIdentifier: config.containerIdentifier,
        host: config.host,
        port: config.port,
        timeout: config.authTimeout
      )
    }
  }

  static func startAuthenticationServer(
    apiToken: String,
    containerIdentifier: String,
    host: String,
    port: Int,
    timeout: Double = 300
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
    print("   Timeout: \(formatTimeout(timeout))")
    print("   Press Ctrl+C to cancel")

    do {
      let token = try await withTimeoutAndSignals(seconds: timeout) {
        await tokenChannel.receive()
      }

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

    } catch let error as AsyncTimeoutError {
      serverTask.cancel()

      switch error {
      case .timeout(let message):
        print("\n❌ \(message)")
        print("💡 Try increasing timeout with --auth-timeout <seconds>")
      case .cancelled(let message):
        print("\n❌ \(message)")
        print("💡 Authentication cancelled by user")
      }

      throw error
    } catch {
      serverTask.cancel()
      throw error
    }
  }

  static func runCloudKitDemo(
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
      let records = try await cloudKitService.queryRecords(recordType: "Note", limit: 5)
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
    print("   mistdemo --api-token \"\(apiToken.maskedAPIToken)\" \\")
    print("            --web-auth-token \"\(webAuthToken)\"")
    print("   (Authentication server is automatically skipped when token is provided)")
  }

  /// Test all authentication methods
  static func testAllAuthenticationMethods(
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

    // Test 1: API-only Authentication
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

    // Test 2: Web Authentication
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

    // Test 3: AdaptiveTokenManager
    print("\n🔄 Test 3: AdaptiveTokenManager Transitions")
    print(String(repeating: "-", count: 50))
    await testAdaptiveTokenManagerInternal(apiToken: apiToken, webAuthToken: webAuthToken)

    // Test 4: Server-to-Server Authentication
    print("\n🔐 Test 4: Server-to-Server Authentication (Test Keys)")
    print(String(repeating: "-", count: 50))
    print("⚠️  Server-to-server authentication requires real keys from Apple Developer Console")
    print("   Use --test-server-to-server with --key-id and --private-key-file for testing")

    print("\n" + String(repeating: "=", count: 70))
    print("✅ Authentication test suite completed!")
    print(String(repeating: "=", count: 70))
  }

  /// Test API-only authentication
  static func testAPIOnlyAuthentication(
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
      let records = try await service.queryRecords(recordType: "Note", limit: 5)
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

  /// Test AdaptiveTokenManager
  static func testAdaptiveTokenManager(
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

  /// Internal AdaptiveTokenManager test implementation
  static func testAdaptiveTokenManagerInternal(
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

  /// Test server-to-server authentication
  static func testServerToServerAuthentication(
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
        let records = try await service.queryRecords(recordType: "Note", limit: 5)
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
