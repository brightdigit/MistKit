//
//  AuthTokenCommand.swift
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

public import Foundation
import Hummingbird
import Logging
import MistKit

/// Command to obtain web authentication token via browser flow
public struct AuthTokenCommand: MistDemoCommand {
    public static let commandName = "auth-token"
    public static let abstract = "Obtain a web authentication token via browser flow"
    
    private let config: AuthTokenConfig
    
    public init(config: AuthTokenConfig) {
        self.config = config
    }
    
    /// Initialize from command line arguments using Swift Configuration
    public init() throws {
        let configReader = try MistDemoConfiguration()
        
        // Parse command-specific options
        let apiToken = configReader.string(forKey: "api.token", isSecret: true) ?? ""
        guard !apiToken.isEmpty else {
            throw ConfigurationError.missingRequired("api.token", 
                suggestion: "Provide via --api-token or CLOUDKIT_API_TOKEN environment variable")
        }
        
        let port = configReader.int(forKey: "port", default: 8080) ?? 8080
        let host = configReader.string(forKey: "host", default: "127.0.0.1") ?? "127.0.0.1"
        let noBrowser = configReader.bool(forKey: "no.browser", default: false)
        
        self.config = AuthTokenConfig(
            apiToken: apiToken,
            port: port,
            host: host,
            noBrowser: noBrowser
        )
    }
    
    public func execute() async throws {
        print("🚀 Starting CloudKit Authentication Server")
        print("📍 Server URL: http://\(config.host):\(config.port)")
        print("🔑 API Token: \(config.apiToken.maskedAPIToken)")
        
        let tokenChannel = AsyncChannel<String>()
        let responseCompleteChannel = AsyncChannel<Void>()
        
        let router = Router(context: BasicRequestContext.self)
        router.middlewares.add(LogRequestsMiddleware(.info))
        
        // Find and serve static resources (index.html)
        let resourcesPath = try findResourcesPath()
        print("📁 Serving static files from: \(resourcesPath)")
        
        router.middlewares.add(
            FileMiddleware(
                resourcesPath,
                searchForIndexHtml: true
            )
        )
        
        // API endpoint for authentication callback
        let api = router.group("api")
        api.post("authenticate") { request, context -> Response in
            let authRequest = try await request.decode(as: AuthRequest.self, context: context)
            await tokenChannel.send(authRequest.sessionToken)
            
            // Validate the received token quickly
            let response = AuthResponse(
                userRecordName: authRequest.userRecordName,
                cloudKitData: .init(user: nil, zones: [], error: nil),
                message: "Authentication successful! Token received."
            )
            
            let jsonData = try JSONEncoder().encode(response)
            
            // Signal completion after a brief delay
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
        
        // Start the HTTP server
        let app = Application(
            router: router,
            configuration: .init(
                address: .hostname(config.host, port: config.port)
            )
        )
        
        let serverTask = Task {
            try await app.runService()
        }
        
        // Open browser unless disabled
        if !config.noBrowser {
            Task {
                try await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
                print("🌐 Opening browser...")
                BrowserOpener.openBrowser(url: "http://\(config.host):\(config.port)")
            }
        } else {
            print("ℹ️  Browser opening disabled. Navigate to http://\(config.host):\(config.port) manually")
        }
        
        print("⏳ Waiting for authentication...")
        
        // Wait for token with timeout
        let token: String
        do {
            token = try await withTimeout(seconds: 300) {
                await tokenChannel.receive()
            }
        } catch {
            serverTask.cancel()
            throw AuthTokenError.timeout("Authentication timed out after 5 minutes")
        }
        
        print("✅ Authentication successful! Received token.")
        
        // Wait for response completion
        await responseCompleteChannel.receive()
        
        // Shutdown server
        serverTask.cancel()
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Output token to stdout (this is the main output of the command)
        print(token)
    }
    
    /// Find the resources directory containing index.html
    private func findResourcesPath() throws -> String {
        let possiblePaths = [
            Bundle.main.resourcePath ?? "",
            Bundle.main.bundlePath + "/Contents/Resources",
            "./Sources/MistDemo/Resources",
            "./Examples/MistDemo/Sources/MistDemo/Resources",
            URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources").path
        ]
        
        for path in possiblePaths {
            if !path.isEmpty && FileManager.default.fileExists(atPath: path + "/index.html") {
                return path
            }
        }
        
        throw AuthTokenError.missingResource("index.html not found in any expected location")
    }
}

/// Helper function for timeout operations
private func withTimeout<T: Sendable>(seconds: Double, operation: @escaping @Sendable () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            return try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw AuthTokenError.timeout("Operation timed out after \(seconds) seconds")
        }
        
        guard let result = try await group.next() else {
            throw AuthTokenError.timeout("Timeout task failed")
        }
        
        group.cancelAll()
        return result
    }
}

/// Authentication-related errors for auth-token command
public enum AuthTokenError: Error, LocalizedError {
    case timeout(String)
    case missingResource(String)
    case serverError(String)
    
    public var errorDescription: String? {
        switch self {
        case .timeout(let message):
            return "Authentication timeout: \(message)"
        case .missingResource(let resource):
            return "Missing resource: \(resource)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}