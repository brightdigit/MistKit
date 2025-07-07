import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import HTTPTypes
import HTTPTypes

/// A client for interacting with CloudKit Web Services
public struct MistKitClient {
    /// The underlying OpenAPI client
    public let client: Client
    
    /// The CloudKit container configuration
    public let configuration: MistKitConfiguration
    
    /// Initialize a new MistKit client
    /// - Parameter configuration: The CloudKit configuration including container, environment, and authentication
    public init(configuration: MistKitConfiguration) throws {
        self.configuration = configuration
        
        // Create the OpenAPI client with custom server URL and middleware
        self.client = Client(
            serverURL: configuration.serverURL,
            transport: URLSessionTransport(),
            middlewares: [
                AuthenticationMiddleware(configuration: configuration),
                LoggingMiddleware()
            ]
        )
    }
}

// MARK: - Configuration

/// Configuration for MistKit client
public struct MistKitConfiguration : Sendable {
    /// The CloudKit container identifier (e.g., "iCloud.com.example.app")
    public let container: String
    
    /// The CloudKit environment
    public let environment: Environment
    
    /// The CloudKit database type
    public let database: Database
    
    /// API Token for authentication
    public let apiToken: String
    
    /// Optional Web Auth Token for user authentication
    public let webAuthToken: String?
    
    /// Protocol version (currently "1")
    public let version: String = "1"
    
    /// Computed server URL based on configuration
    public var serverURL: URL {
        URL(string: "https://api.apple-cloudkit.com")!
    }
    
    public init(
        container: String,
        environment: Environment,
        database: Database = .private,
        apiToken: String,
        webAuthToken: String? = nil
    ) {
        self.container = container
        self.environment = environment
        self.database = database
        self.apiToken = apiToken
        self.webAuthToken = webAuthToken
    }
}

// MARK: - Enums

/// CloudKit environment types
public enum Environment: String, Sendable {
    case development
    case production
}

/// CloudKit database types
public enum Database: String, Sendable  {
    case `public`
    case `private`
    case shared
}

// MARK: - Middleware

/// Authentication middleware for CloudKit requests
struct AuthenticationMiddleware: ClientMiddleware {
    let configuration: MistKitConfiguration
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var modifiedRequest = request
        
        // Get the current path
        let requestPath = request.path ?? ""
        let fullURLString = baseURL.absoluteString + (requestPath.hasPrefix("/") ? String(requestPath.dropFirst()) : requestPath)
        
        // Parse and add authentication query parameters
        var urlComponents = URLComponents(string: fullURLString)!
        var queryItems = urlComponents.queryItems ?? []
        
        // Parse existing query items from the request if any
        if let queryString = request.path?.split(separator: "?").last {
            let existingQuery = String(queryString)
            if let existingComponents = URLComponents(string: "?" + existingQuery) {
                queryItems.append(contentsOf: existingComponents.queryItems ?? [])
            }
        }
        
        queryItems.append(URLQueryItem(name: "ckAPIToken", value: configuration.apiToken))
        if let webAuthToken = configuration.webAuthToken {
            queryItems.append(URLQueryItem(name: "ckWebAuthToken", value: webAuthToken))
        }
        
        urlComponents.queryItems = queryItems
        
        // Update the request path with query parameters
        if let updatedURL = urlComponents.url {
            let newPath = updatedURL.absoluteString.replacingOccurrences(of: baseURL.absoluteString, with: "/")
            modifiedRequest.path = newPath
        }
        
        return try await next(modifiedRequest, body, baseURL)
    }
}

/// Logging middleware for debugging
struct LoggingMiddleware: ClientMiddleware {
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        #if DEBUG
        let fullPath = baseURL.absoluteString + (request.path ?? "")
        print("🌐 CloudKit Request: \(request.method.rawValue) \(fullPath)")
        #endif
        
        let (response, responseBody) = try await next(request, body, baseURL)
        
        #if DEBUG
        print("✅ CloudKit Response: \(response.status.code)")
        #endif
        
        return (response, responseBody)
    }
}
