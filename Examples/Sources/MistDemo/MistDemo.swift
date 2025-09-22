import Foundation
import MistKit
import OpenAPIRuntime
import OpenAPIURLSession
import Hummingbird
import ArgumentParser
import Crypto
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

    @Flag(name: .long, help: "Test signature generation")
    var testSignature: Bool = false

    @Option(name: .long, help: "Server-to-server key ID")
    var keyID: String?

    @Option(name: .long, help: "Server-to-server private key (PEM format)")
    var privateKey: String?

    @Option(name: .long, help: "Path to private key file")
    var privateKeyFile: String?

    @Option(name: .long, help: "CloudKit environment (development or production)")
    var environment: String = "development"
    
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
        
        if testAllAuth {
            try await testAllAuthenticationMethods(apiToken: effectiveApiToken)
        } else if testApiOnly {
            try await testAPIOnlyAuthentication(apiToken: effectiveApiToken)
        } else if testAdaptive {
            try await testAdaptiveTokenManager(apiToken: effectiveApiToken)
        } else if testServerToServer {
            try await testServerToServerAuthentication(apiToken: effectiveApiToken)
        } else if testSignature {
            testSignatureGeneration()
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
                        try await writer.write(ByteBuffer(data: jsonData))
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
        if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
            await testServerToServerBasic()
        } else {
            print("⚠️  Server-to-server authentication requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+")
            print("   Use API-only or Web authentication on older platforms")
        }

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
            // Generate a test key
            print("🔧 No private key provided, generating test key...")
            if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
                let testKeys = generateTestKeys()
                privateKeyPEM = testKeys.privateKeyPEM
                keyIdentifier = testKeys.keyID
                print("✅ Generated test key ID: \(keyIdentifier)")
                print("⚠️  Note: This is a test key and won't work with real CloudKit")
            } else {
                print("❌ Key generation requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+")
                print("💡 Provide a key manually using --private-key-file or --private-key")
                return
            }
        }

        // Use provided key ID or default test ID
        if let providedKeyID = keyID {
            keyIdentifier = providedKeyID
            print("🔑 Using provided key ID: \(keyIdentifier)")
        } else if keyID == nil && privateKey == nil && privateKeyFile == nil {
            // keyIdentifier already set from test key generation
        } else {
            print("❌ Key ID is required when providing a private key")
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

                // Try listing zones first (GET request with no body)
//                print("\n📁 Testing zone listing with server-to-server authentication...")
//                let zones = try await service.listZones()
//                print("✅ Found \(zones.count) zone(s):")
//                for zone in zones.prefix(3) {
//                    print("   • Zone: \(zone.zoneName)")
//                }

                // Query public records
                print("\n📋 Querying public records with server-to-server authentication...")
                let records = try await service.queryRecords(recordType: "TodoItem", limit: 5)
                print("✅ Found \(records.count) public record(s):")
                for record in records.prefix(3) {
                    print("   • Record: \(record.recordName)")
                }
//
//                // Try to fetch current user (should work with server-to-server)
//                print("\n👤 Testing user operations...")
//                let userInfo = try await service.fetchCurrentUser()
//                print("✅ Server identity: \(userInfo.userRecordName)")
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

    /// Basic server-to-server test for comprehensive suite
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    private func testServerToServerBasic() async {
        do {
            print("📋 Testing server-to-server authentication basics...")
            let testKeys = generateTestKeys()
            let serverManager = try ServerToServerAuthManager(
                keyID: testKeys.keyID,
                pemString: testKeys.privateKeyPEM
            )

            let isValid = try await serverManager.validateCredentials()
            print("✅ Server-to-server validation: \(isValid ? "PASSED" : "FAILED")")
            print("✅ Key generation and authentication setup working")
        } catch {
            print("❌ Server-to-server basic test failed: \(error)")
        }
    }

    /// Generate test keys for server-to-server authentication testing
    /// Available on macOS 11.0+, iOS 14.0+, tvOS 14.0+, watchOS 7.0+, and Linux
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    private func generateTestKeys() -> (keyID: String, privateKeyPEM: String) {
        // Generate a new P-256 private key
        let privateKey = P256.Signing.PrivateKey()

        // Generate a test key ID (8-character random string)
        let keyID = String((0..<8).compactMap { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement() })

        // Convert to PEM format
        let privateKeyPEM = privateKey.pemRepresentation
        return (keyID: keyID, privateKeyPEM: privateKeyPEM)
    }
}
