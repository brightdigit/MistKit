import Foundation
import MistKit
import OpenAPIRuntime
import OpenAPIURLSession
import Hummingbird
import ArgumentParser
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
    var containerIdentifier: String = "iCloud.com.example.mistkit"
    
    @Option(name: .shortAndLong, help: "CloudKit API token")
    var apiToken: String = "YOUR_API_TOKEN"
    
    @Option(name: .long, help: "Host to bind the server to")
    var host: String = "127.0.0.1"
    
    @Option(name: .shortAndLong, help: "Port to bind the server to")
    var port: Int = 8080
    
    @Flag(name: .long, help: "Skip authentication and use provided web auth token")
    var skipAuth: Bool = false
    
    @Option(name: .long, help: "Web auth token (use with --skip-auth)")
    var webAuthToken: String?
    
    func run() async throws {
        if skipAuth, let token = webAuthToken {
            // Run demo directly with provided token
            try await runCloudKitDemo(webAuthToken: token)
        } else {
            // Start server and wait for authentication
            try await startAuthenticationServer()
        }
    }
    
    func startAuthenticationServer() async throws {
        print("\n" + String(repeating: "=", count: 60))
        print("🚀 MistKit CloudKit Authentication Server")
        print(String(repeating: "=", count: 60))
        print("\n📍 Server URL: http://\(host):\(port)")
        print("📱 Container: \(containerIdentifier)")
        print("\n" + String(repeating: "-", count: 60))
        print("📋 Instructions:")
        print("1. Opening browser to: http://\(host):\(port)")
        print("2. Click 'Sign In with Apple ID'")
        print("3. Authenticate with your Apple ID")
        print("4. The demo will run automatically after authentication")
        print(String(repeating: "-", count: 60))
        print("\n⚠️  Before authenticating, update these in the web page:")
        print("   • containerIdentifier: '\(containerIdentifier)'")
        print("   • apiToken: 'YOUR_API_TOKEN'")
        print(String(repeating: "=", count: 60) + "\n")
        
        // Create a channel to receive the authentication token
        let tokenChannel = AsyncChannel<String>()
        
        let router = Router()
        router.middlewares.add(LogRequestsMiddleware(.info))
        
        // Serve static files
        router.middlewares.add(
            FileMiddleware(
                Bundle.module.bundleURL.appendingPathComponent("Resources").path,
                searchForIndexHtml: true
            )
        )
        
        // Initialize CloudKit service
        let cloudKitService = try CloudKitService(
            containerIdentifier: containerIdentifier,
            apiToken: apiToken
        )
        
        // API routes
        router.group("api") { api in
            // Authentication endpoint
            api.post("authenticate") { request, context in
                struct AuthRequest: Decodable {
                    let sessionToken: String
                    let userRecordName: String
                }
                
                struct AuthResponse: Encodable {
                    let userRecordName: String
                    let cloudKitData: CloudKitData
                    let message: String
                    
                    struct CloudKitData: Encodable {
                        let user: UserInfo?
                        let zones: [ZoneInfo]
                        let error: String?
                    }
                }
                
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
                    userData = try await cloudKitService.fetchCurrentUser(webAuthToken: webAuthToken)
                    zones = try await cloudKitService.listZones(webAuthToken: webAuthToken)
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
                
                return Response(status: .ok, body: .init(data: try JSONEncoder().encode(response)))
            }
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
            openBrowser(url: "http://\(host):\(port)")
        }
        
        // Wait for authentication token
        print("\n⏳ Waiting for authentication...")
        let token = await tokenChannel.receive()
        
        print("\n✅ Authentication successful! Received session token.")
        print("🔄 Shutting down server...")
        
        // Shutdown the server
        serverTask.cancel()
        
        // Give it a moment to clean up
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Run the demo with the token
        print("\n📱 Starting CloudKit demo...\n")
        try await runCloudKitDemo(webAuthToken: token)
    }
    
    func runCloudKitDemo(webAuthToken: String) async throws {
        print(String(repeating: "=", count: 50))
        print("🌩️  MistKit CloudKit Demo")
        print(String(repeating: "=", count: 50))
        print("Container: \(containerIdentifier)")
        print("Environment: development")
        print(String(repeating: "-", count: 50))
        
        // Initialize the OpenAPI client
        let client = Client(
            serverURL: URL(string: "https://api.apple-cloudkit.com")!,
            transport: URLSessionTransport()
        )
        
        // Fetch current user
        print("\n👤 Fetching current user...")
        do {
            let response = try await client.users_current_get(
                path: .init(
                    version: "1",
                    container: containerIdentifier,
                    environment: "development",
                    database: "private"
                ),
                headers: .init(
                    X_hyphen_Apple_hyphen_CloudKit_hyphen_API_hyphen_Token: apiToken,
                    X_hyphen_Apple_hyphen_CloudKit_hyphen_Web_hyphen_Auth_hyphen_Token: webAuthToken
                )
            )
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let userData):
                    print("✅ User Record Name: \(userData.userRecordName ?? "Unknown")")
                    if let firstName = userData.firstName {
                        print("   First Name: \(firstName)")
                    }
                    if let lastName = userData.lastName {
                        print("   Last Name: \(lastName)")
                    }
                    if let email = userData.emailAddress {
                        print("   Email: \(email)")
                    }
                }
            case .undocumented(let statusCode, _):
                print("❌ Error: HTTP \(statusCode)")
            }
        } catch {
            print("❌ Failed to fetch user: \(error)")
        }
        
        // List zones
        print("\n📁 Listing zones...")
        do {
            let response = try await client.zones_list_get(
                path: .init(
                    version: "1",
                    container: containerIdentifier,
                    environment: "development",
                    database: "private"
                ),
                headers: .init(
                    X_hyphen_Apple_hyphen_CloudKit_hyphen_API_hyphen_Token: apiToken,
                    X_hyphen_Apple_hyphen_CloudKit_hyphen_Web_hyphen_Auth_hyphen_Token: webAuthToken
                )
            )
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let zonesData):
                    if let zones = zonesData.zones {
                        print("✅ Found \(zones.count) zone(s):")
                        for zone in zones {
                            if let zoneName = zone.zoneID?.zoneName {
                                print("   • \(zoneName)")
                                if let capabilities = zone.capabilities {
                                    print("     Capabilities: \(capabilities.joined(separator: ", "))")
                                }
                            }
                        }
                    }
                }
            case .undocumented(let statusCode, _):
                print("❌ Error: HTTP \(statusCode)")
            }
        } catch {
            print("❌ Failed to list zones: \(error)")
        }
        
        // Query records
        print("\n📋 Querying records...")
        do {
            let requestBody = Components.Schemas.RecordsQueryRequest(
                query: .init(
                    recordType: "TestRecord",
                    sortBy: [
                        .init(
                            fieldName: "modificationDate",
                            ascending: false
                        )
                    ]
                ),
                resultsLimit: 5,
                zoneID: .init(
                    zoneName: "_defaultZone"
                )
            )
            
            let response = try await client.records_query_post(
                path: .init(
                    version: "1",
                    container: containerIdentifier,
                    environment: "development",
                    database: "private"
                ),
                headers: .init(
                    X_hyphen_Apple_hyphen_CloudKit_hyphen_API_hyphen_Token: apiToken,
                    X_hyphen_Apple_hyphen_CloudKit_hyphen_Web_hyphen_Auth_hyphen_Token: webAuthToken
                ),
                body: .json(requestBody)
            )
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let recordsData):
                    if let records = recordsData.records, !records.isEmpty {
                        print("✅ Found \(records.count) record(s)")
                        for record in records.prefix(3) {
                            print("\n   Record: \(record.recordName ?? "Unknown")")
                            print("   Type: \(record.recordType ?? "Unknown")")
                            if let fields = record.fields {
                                print("   Fields:")
                                for (key, field) in fields {
                                    if let value = field.value {
                                        print("     • \(key): \(value)")
                                    }
                                }
                            }
                        }
                    } else {
                        print("ℹ️  No records found")
                    }
                }
            case .undocumented(let statusCode, _):
                print("❌ Error: HTTP \(statusCode)")
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
    
    func openBrowser(url: String) {
        #if canImport(AppKit)
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
        #elseif os(Linux)
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["xdg-open", url]
        try? process.run()
        #endif
    }
}

// AsyncChannel for communication between server and main thread
actor AsyncChannel<T> {
    private var value: T?
    private var continuation: CheckedContinuation<T, Never>?
    
    func send(_ newValue: T) {
        if let continuation = continuation {
            continuation.resume(returning: newValue)
            self.continuation = nil
        } else {
            value = newValue
        }
    }
    
    func receive() async -> T {
        if let value = value {
            self.value = nil
            return value
        }
        
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
}