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
    var containerIdentifier: String = "iCloud.com.brightdigit.MistDemo"
    
    @Option(name: .shortAndLong, help: "CloudKit API token")
    var apiToken: String = "296c503003846ef692cb5b56c4a63cc1d27fb952eebe259d73e692759286dfa6"
    
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
                    print("   Fields: \(formatFields(record.fields))")
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
    
    /// Format FieldValue fields for display
    private func formatFields(_ fields: [String: FieldValue]) -> String {
        if fields.isEmpty {
            return "{}"
        }
        
        let formattedFields = fields.map { (key, value) in
            let valueString = formatFieldValue(value)
            return "\(key): \(valueString)"
        }.joined(separator: ", ")
        
        return "{\(formattedFields)}"
    }
    
    /// Format a single FieldValue for display
    private func formatFieldValue(_ value: FieldValue) -> String {
        switch value {
        case .string(let string):
            return "\"\(string)\""
        case .int64(let int):
            return "\(int)"
        case .double(let double):
            return "\(double)"
        case .boolean(let bool):
            return "\(bool)"
        case .bytes(let bytes):
            return "bytes(\(bytes.prefix(20)))"
        case .date(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "date(\(formatter.string(from: date)))"
        case .location(let location):
            return "location(\(location.latitude), \(location.longitude))"
        case .reference(let reference):
            return "reference(\(reference.recordName))"
        case .asset(let asset):
            return "asset(\(asset.downloadURL ?? "no URL"))"
        case .list(let values):
            let formattedValues = values.map { formatFieldValue($0) }.joined(separator: ", ")
            return "[\(formattedValues)]"
        }
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
