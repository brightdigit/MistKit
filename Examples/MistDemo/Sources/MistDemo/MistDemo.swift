import Foundation
import MistKit
import Hummingbird
import ArgumentParser
import Logging
#if canImport(AppKit)
import AppKit
#endif

@main
struct MistDemo: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mistdemo",
        abstract: "MistKit demo with CloudKit authentication server"
    )
    
    @Option(name: .shortAndLong, help: "CloudKit container identifier")
    var containerIdentifier: String = "iCloud.com.brightdigit.MistDemo"
    
    @Option(name: .shortAndLong, help: "CloudKit API token (or set CLOUDKIT_API_TOKEN environment variable)")
    var apiToken: String = ""
    
    @Option(name: .long, help: "Host to bind the server to")
    var host: String = "127.0.0.1"
    
    @Option(name: .shortAndLong, help: "Port to bind the server to")
    var port: Int = 8080
    
    @Flag(name: .long, help: "Skip authentication and use provided web auth token")
    var skipAuth: Bool = false

    @Option(name: .long, help: "Web auth token (use with --skip-auth)")
    var webAuthToken: String?

    @Flag(name: .long, help: "Test all authentication methods")
    var testAllAuth: Bool = false

    @Flag(name: .long, help: "Test API-only authentication")
    var testApiOnly: Bool = false

    @Flag(name: .long, help: "Test AdaptiveTokenManager transitions")
    var testAdaptive: Bool = false

    @Flag(name: .long, help: "Test server-to-server authentication")
    var testServerToServer: Bool = false


    @Option(name: .long, help: "Server-to-server key ID")
    var keyID: String?

    @Option(name: .long, help: "Server-to-server private key (PEM format)")
    var privateKey: String?

    @Option(name: .long, help: "Path to private key file")
    var privateKeyFile: String?

    @Option(name: .long, help: "CloudKit environment (development or production)")
    var environment: String = "development"

    @Flag(name: .long, help: "Test lookupZones operation")
    var testLookupZones: Bool = false

    @Option(name: .long, help: "Comma-separated zone names to lookup")
    var zoneNames: String?

    @Flag(name: .long, help: "Test fetchRecordChanges operation")
    var testFetchChanges: Bool = false

    @Option(name: .long, help: "Sync token from previous fetch")
    var syncToken: String?

    @Flag(name: .long, help: "Fetch all changes automatically (pagination)")
    var fetchAll: Bool = false

    @Flag(name: .long, help: "Test uploadAssets operation")
    var testUploadAsset: Bool = false

    @Option(name: .long, help: "Path to file to upload")
    var file: String?

    @Option(name: .long, help: "Create record of this type with uploaded asset")
    var createRecord: String?

    func run() async throws {
        // Get API token from environment variable if not provided
        let resolvedApiToken = apiToken.isEmpty ? 
            EnvironmentConfig.getOptional(EnvironmentConfig.Keys.cloudKitAPIToken) ?? "" : 
            apiToken
        
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
        
        // Use the resolved API token for all operations
        let effectiveApiToken = resolvedApiToken
        
        if testLookupZones {
            try await demonstrateLookupZones(apiToken: effectiveApiToken)
        } else if testFetchChanges {
            try await demonstrateFetchChanges(apiToken: effectiveApiToken)
        } else if testUploadAsset {
            try await demonstrateUploadAsset(apiToken: effectiveApiToken)
        } else if testAllAuth {
            try await testAllAuthenticationMethods(apiToken: effectiveApiToken)
        } else if testApiOnly {
            try await testAPIOnlyAuthentication(apiToken: effectiveApiToken)
        } else if testAdaptive {
            try await testAdaptiveTokenManager(apiToken: effectiveApiToken)
        } else if testServerToServer {
            try await testServerToServerAuthentication(apiToken: effectiveApiToken)
        } else if skipAuth, let token = webAuthToken {
            // Run demo directly with provided token
            try await runCloudKitDemo(webAuthToken: token, apiToken: effectiveApiToken)
        } else {
            // Start server and wait for authentication
            try await startAuthenticationServer(apiToken: effectiveApiToken)
        }
    }
    
    func startAuthenticationServer(apiToken: String) async throws {
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
        
        // Create channels for communication
        let tokenChannel = AsyncChannel<String>()
        let responseCompleteChannel = AsyncChannel<Void>()
        
        let router = Router(context: BasicRequestContext.self)
        router.middlewares.add(LogRequestsMiddleware(.info))
        
        // Serve static files - try multiple potential paths
        let possiblePaths = [
            Bundle.main.resourcePath ?? "",
            Bundle.main.bundlePath + "/Contents/Resources",
            "./Sources/MistDemo/Resources",
            "./Examples/Sources/MistDemo/Resources",
            URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Resources").path
        ]
        
        var resourcesPath = "./Sources/MistDemo/Resources" // default fallback
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
        
        // API routes  
        let api = router.group("api")
        // Authentication endpoint
        api.post("authenticate") { request, context -> Response in
                let authRequest = try await request.decode(as: AuthRequest.self, context: context)
                
                // Send token to the channel
                await tokenChannel.send(authRequest.sessionToken)
                
                // Use the session token as web auth token
                let webAuthToken = authRequest.sessionToken
                
                var userData: UserInfo?
                var zones: [ZoneInfo] = []
                var errorMessage: String?
                
                // Try to fetch user data and zones
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
                
                // Notify that the response is about to be sent
                Task {
                    // Give a small delay to ensure response is fully sent
                    try await Task.sleep(nanoseconds: 200_000_000) // 200ms
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
        
        // Start server in background
        let serverTask = Task {
            try await app.runService()
        }
        
        // Open browser after server starts
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
            print("🌐 Opening browser...")
            BrowserOpener.openBrowser(url: "http://\(host):\(port)")
        }
        
        // Wait for authentication token
        print("\n⏳ Waiting for authentication...")
        let token = await tokenChannel.receive()
        
        print("\n✅ Authentication successful! Received session token.")
        print("⏳ Waiting for response to complete...")
        
        // Wait for the response to be fully sent to the web page
        await responseCompleteChannel.receive()
        
        print("🔄 Shutting down server...")
        
        // Shutdown the server
        serverTask.cancel()
        
        // Give it a moment to clean up
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Run the demo with the token
        print("\n📱 Starting CloudKit demo...\n")
        try await runCloudKitDemo(webAuthToken: token, apiToken: apiToken)
    }
    
    func runCloudKitDemo(webAuthToken: String, apiToken: String) async throws {
        print(String(repeating: "=", count: 50))
        print("🌩️  MistKit CloudKit Demo")
        print(String(repeating: "=", count: 50))
        print("Container: \(containerIdentifier)")
        print("Environment: development")
        print(String(repeating: "-", count: 50))
        
        // Initialize CloudKit service
        let cloudKitService = try CloudKitService(
            containerIdentifier: containerIdentifier,
            apiToken: apiToken,
            webAuthToken: webAuthToken
        )
        
        // Fetch current user
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
        
        // List zones
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
        
        // Query records
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
        
        // Print usage tip
        print("\n💡 Tip: You can skip authentication next time by running:")
        print("   mistdemo --skip-auth --web-auth-token \"\(webAuthToken)\"")
    }

    /// Test all authentication methods
    func testAllAuthenticationMethods(apiToken: String) async throws {
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
                environment: .development,
                database: .public
            )

            // Validate credentials
            print("📋 Validating API token credentials...")
            let isValid = try await apiTokenManager.validateCredentials()
            print("✅ API Token validation: \(isValid ? "PASSED" : "FAILED")")

            // List zones (public database)
            print("📁 Listing public zones...")
            let zones = try await service.listZones()
            print("✅ Found \(zones.count) public zone(s)")

        } catch {
            print("❌ API-only authentication test failed: \(error)")
        }

        // Test 2: Web Authentication (requires manual token)
        print("\n🌐 Test 2: Web Authentication (Private Database)")
        print(String(repeating: "-", count: 50))
        if let webToken = webAuthToken {
            do {
                let webTokenManager = WebAuthTokenManager(apiToken: apiToken, webAuthToken: webToken)
                let service = try CloudKitService(
                    containerIdentifier: containerIdentifier,
                    tokenManager: webTokenManager,
                    environment: .development,
                    database: .private
                )

                // Validate credentials
                print("📋 Validating web auth credentials...")
                let isValid = try await webTokenManager.validateCredentials()
                print("✅ Web Auth validation: \(isValid ? "PASSED" : "FAILED")")

                // Fetch current user
                print("👤 Fetching current user...")
                let userInfo = try await service.fetchCurrentUser()
                print("✅ User: \(userInfo.userRecordName)")

                // List zones
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
        await testAdaptiveTokenManagerInternal(apiToken: apiToken)

        // Test 4: Server-to-Server Authentication (basic test only)
        print("\n🔐 Test 4: Server-to-Server Authentication (Test Keys)")
        print(String(repeating: "-", count: 50))
        print("⚠️  Server-to-server authentication requires real keys from Apple Developer Console")
        print("   Use --test-server-to-server with --key-id and --private-key-file for testing")

        print("\n" + String(repeating: "=", count: 70))
        print("✅ Authentication test suite completed!")
        print(String(repeating: "=", count: 70))
    }

    /// Test API-only authentication
    func testAPIOnlyAuthentication(apiToken: String) async throws {
        print("\n" + String(repeating: "=", count: 60))
        print("🔐 API-only Authentication Test")
        print(String(repeating: "=", count: 60))
        print("Container: \(containerIdentifier)")
        print("Database: public (API-only limitation)")
        print(String(repeating: "-", count: 60))

        do {
            // Use API-only service initializer with environment
            let cloudKitEnvironment: MistKit.Environment = environment == "production" ? .production : .development
            let tokenManager = APITokenManager(apiToken: apiToken)
            let service = try CloudKitService(
                containerIdentifier: containerIdentifier, 
                tokenManager: tokenManager,
                environment: cloudKitEnvironment,
                database: .public
            )

            print("\n📋 Testing API-only authentication...")
            print("✅ CloudKitService initialized with API-only authentication")

            // List zones in public database
            print("\n📁 Listing zones in public database...")
            let zones = try await service.listZones()
            print("✅ Found \(zones.count) zone(s):")
            for zone in zones {
                print("   • \(zone.zoneName)")
            }

            // Query records from public database
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

    /// Test AdaptiveTokenManager
    func testAdaptiveTokenManager(apiToken: String) async throws {
        print("\n" + String(repeating: "=", count: 60))
        print("🔄 AdaptiveTokenManager Transition Test")
        print(String(repeating: "=", count: 60))
        await testAdaptiveTokenManagerInternal(apiToken: apiToken)
        print(String(repeating: "=", count: 60))
        print("✅ AdaptiveTokenManager test completed!")
        print(String(repeating: "=", count: 60))
    }

    /// Internal AdaptiveTokenManager test implementation
    func testAdaptiveTokenManagerInternal(apiToken: String) async {
        do {
            print("📋 Creating AdaptiveTokenManager with API token...")
            let adaptiveManager = AdaptiveTokenManager(apiToken: apiToken)

            // Test initial state
            print("🔍 Testing initial API-only state...")
            let initialCredentials = try await adaptiveManager.getCurrentCredentials()
            if case .apiToken(let token) = initialCredentials?.method {
                print("✅ Initial state: API-only authentication (\(String(token.prefix(8)))...)")
            }

            let hasCredentials = await adaptiveManager.hasCredentials
            print("✅ Has credentials: \(hasCredentials)")


            // Test validation
            print("🔍 Testing credential validation...")
            let isValid = try await adaptiveManager.validateCredentials()
            print("✅ Credential validation: \(isValid ? "PASSED" : "FAILED")")

            // Test transition to web auth (if web token available)
            if let webToken = webAuthToken {
                print("🔄 Testing upgrade to web authentication...")
                let upgradedCredentials = try await adaptiveManager.upgradeToWebAuthentication(webAuthToken: webToken)
                if case .webAuthToken(let api, let web) = upgradedCredentials.method {
                    print("✅ Upgraded to web auth (API: \(String(api.prefix(8)))..., Web: \(String(web.prefix(8)))...)")
                }

                // Test validation after upgrade
                let validAfterUpgrade = try await adaptiveManager.validateCredentials()
                print("✅ Validation after upgrade: \(validAfterUpgrade ? "PASSED" : "FAILED")")

                // Test downgrade back to API-only
                print("🔄 Testing downgrade to API-only...")
                let downgradedCredentials = try await adaptiveManager.downgradeToAPIOnly()
                if case .apiToken(let token) = downgradedCredentials.method {
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
    func testServerToServerAuthentication(apiToken: String) async throws {
        print("\n" + String(repeating: "=", count: 60))
        print("🔐 Server-to-Server Authentication Test")
        print(String(repeating: "=", count: 60))
        print("Container: \(containerIdentifier)")
        print("Database: public (server-to-server only supports public database)")
        print("ℹ️  Note: Server-to-server keys must be registered in CloudKit Dashboard")
        print("ℹ️  See: https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html")
        print(String(repeating: "-", count: 60))

        // Get the private key
        let privateKeyPEM: String
        var keyIdentifier: String = ""

        if let keyFile = privateKeyFile {
            // Read from file
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
            // Use provided key
            privateKeyPEM = key
            print("🔑 Using provided private key")
        } else {
            // No private key provided
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

        // Use provided key ID
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
                // Create server-to-server manager
                print("\n📋 Creating ServerToServerAuthManager...")
                let serverManager = try ServerToServerAuthManager(
                    keyID: keyIdentifier,
                    pemString: privateKeyPEM
                )

                print("🔍 Testing server-to-server credentials...")
                let isValid = try await serverManager.validateCredentials()
                print("✅ Credential validation: \(isValid ? "PASSED" : "FAILED")")

                // Test with CloudKit service
                print("\n🌐 Testing CloudKit integration...")
                let cloudKitEnvironment: MistKit.Environment = environment == "production" ? .production : .development
                let service = try CloudKitService(
                    containerIdentifier: containerIdentifier,
                    tokenManager: serverManager,
                    environment: cloudKitEnvironment,
                    database: .public  // Server-to-server only supports public database
                )

                print("✅ CloudKitService initialized with server-to-server authentication (public database only)")

                // Query public records
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

            // Provide helpful setup guidance based on Apple's documentation
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

    // MARK: - New Operation Demonstrations

    private func demonstrateLookupZones(apiToken: String) async throws {
        print("\n" + String(repeating: "=", count: 60))
        print("🔍 Testing lookupZones() Operation")
        print(String(repeating: "=", count: 60))

        let tokenManager = APITokenManager(apiToken: apiToken)
        let service = try CloudKitService(
            containerIdentifier: containerIdentifier,
            tokenManager: tokenManager,
            environment: environment == "production" ? .production : .development,
            database: .public
        )

        let zoneNamesList = self.zoneNames?.split(separator: ",").map(String.init) ?? ["_defaultZone"]
        let zoneIDs = zoneNamesList.map { ZoneID(zoneName: $0, ownerName: nil) }

        print("\n📋 Looking up \(zoneIDs.count) zone(s):")
        for zoneName in zoneNamesList {
            print("   - \(zoneName)")
        }

        do {
            let zones = try await service.lookupZones(zoneIDs: zoneIDs)
            print("\n✅ Found \(zones.count) zone(s):")
            for zone in zones {
                print("   - \(zone.zoneName)")
                if let owner = zone.ownerRecordName {
                    print("     Owner: \(owner)")
                }
                if !zone.capabilities.isEmpty {
                    print("     Capabilities: \(zone.capabilities.joined(separator: ", "))")
                }
            }
        } catch {
            print("\n❌ Error: \(error)")
        }

        print("\n" + String(repeating: "=", count: 60))
        print("✅ lookupZones test completed!")
        print(String(repeating: "=", count: 60))
    }

    private func demonstrateFetchChanges(apiToken: String) async throws {
        print("\n" + String(repeating: "=", count: 60))
        print("🔄 Testing fetchRecordChanges() Operation")
        print(String(repeating: "=", count: 60))

        let tokenManager = APITokenManager(apiToken: apiToken)
        let service = try CloudKitService(
            containerIdentifier: containerIdentifier,
            tokenManager: tokenManager,
            environment: environment == "production" ? .production : .development,
            database: .public
        )

        do {
            if fetchAll {
                print("\n📦 Fetching all changes (automatic pagination)...")
                if let token = syncToken {
                    print("   Using sync token: \(token.prefix(20))...")
                } else {
                    print("   Performing initial fetch (no sync token)")
                }

                let (records, newToken) = try await service.fetchAllRecordChanges(
                    syncToken: syncToken
                )
                print("\n✅ Fetched \(records.count) record(s)")
                displayRecords(records, limit: 5)
                if let token = newToken {
                    print("\n💾 New sync token: \(token.prefix(20))...")
                    print("   Save this token to fetch only new changes next time:")
                    print("   mistdemo --test-fetch-changes --sync-token '\(token)'")
                }
            } else {
                print("\n📄 Fetching single page...")
                if let token = syncToken {
                    print("   Using sync token: \(token.prefix(20))...")
                } else {
                    print("   Performing initial fetch (no sync token)")
                }

                let result = try await service.fetchRecordChanges(
                    syncToken: syncToken,
                    resultsLimit: 10
                )
                print("\n✅ Fetched \(result.records.count) record(s)")
                displayRecords(result.records, limit: 5)

                if result.moreComing {
                    print("\n⚠️  More changes available! Use --sync-token with:")
                    if let token = result.syncToken {
                        print("   mistdemo --test-fetch-changes --sync-token '\(token)'")
                    }
                }

                if let token = result.syncToken {
                    print("\n💾 Sync token: \(token.prefix(20))...")
                }
            }
        } catch {
            print("\n❌ Error: \(error)")
        }

        print("\n" + String(repeating: "=", count: 60))
        print("✅ fetchRecordChanges test completed!")
        print(String(repeating: "=", count: 60))
    }

    private func displayRecords(_ records: [RecordInfo], limit: Int) {
        let displayed = records.prefix(limit)
        for record in displayed {
            print("   📝 \(record.recordType) - \(record.recordName)")
            if !record.fields.isEmpty {
                print("      Fields: \(record.fields.keys.joined(separator: ", "))")
            }
        }
        if records.count > limit {
            print("   ... and \(records.count - limit) more")
        }
    }

    private func demonstrateUploadAsset(apiToken: String) async throws {
        print("\n" + String(repeating: "=", count: 60))
        print("📤 Testing uploadAssets() Operation")
        print(String(repeating: "=", count: 60))

        guard let filePath = file else {
            print("\n❌ Error: --file required")
            print("   Usage: mistdemo --test-upload-asset --file path/to/file.png")
            return
        }

        let fileURL = URL(fileURLWithPath: filePath)

        guard FileManager.default.fileExists(atPath: filePath) else {
            print("\n❌ Error: File not found at path: \(filePath)")
            return
        }

        let tokenManager = APITokenManager(apiToken: apiToken)
        let service = try CloudKitService(
            containerIdentifier: containerIdentifier,
            tokenManager: tokenManager,
            environment: environment == "production" ? .production : .development,
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
        } catch {
            print("\n❌ Error: \(error)")
        }

        print("\n" + String(repeating: "=", count: 60))
        print("✅ uploadAssets test completed!")
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
