//
//  MistKitConfiguration.swift
//  MistKit
//
//  Created by Leo Dion on 7/9/25.
//

import Foundation



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
