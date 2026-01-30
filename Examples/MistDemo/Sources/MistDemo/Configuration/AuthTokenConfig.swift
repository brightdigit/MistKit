//
//  AuthTokenConfig.swift
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
public import MistKit
public import ConfigKeyKit

/// Configuration for auth-token command
public struct AuthTokenConfig: Sendable, ConfigurationParseable {
    public let apiToken: String
    public let port: Int
    public let host: String
    public let noBrowser: Bool
    
    public init(apiToken: String, port: Int = 8080, host: String = "127.0.0.1", noBrowser: Bool = false) {
        self.apiToken = apiToken
        self.port = port
        self.host = host
        self.noBrowser = noBrowser
    }
    
    /// Parse configuration from command line arguments
    public init() async throws {
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
        
        self.init(
            apiToken: apiToken,
            port: port,
            host: host,
            noBrowser: noBrowser
        )
    }
}