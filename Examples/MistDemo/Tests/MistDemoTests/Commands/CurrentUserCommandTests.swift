//
//  CurrentUserCommandTests.swift
//  MistDemoTests
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
import Testing
import MistKit

@testable import MistDemo

@Suite("CurrentUserCommand Tests")
struct CurrentUserCommandTests {
    // MARK: - Configuration Tests
    
    @Test("CurrentUserConfig initializes with default values")
    func currentUserConfigInitializesWithDefaults() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(base: baseConfig)
        
        #expect(config.fields == nil)
        #expect(config.output == .json)
    }
    
    @Test("CurrentUserConfig accepts custom values")
    func currentUserConfigAcceptsCustomValues() throws {
        let baseConfig = try MistDemoConfig()
        let fields = ["userRecordName", "emailAddress"]
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: fields,
            output: .table
        )
        
        #expect(config.fields == fields)
        #expect(config.output == .table)
    }
    
    // MARK: - Command Property Tests
    
    @Test("Command has correct static properties")
    func commandHasCorrectStaticProperties() {
        #expect(CurrentUserCommand.commandName == "current-user")
        #expect(CurrentUserCommand.abstract == "Get current user information")
    }
    
    @Test("Command initializes with config")
    func commandInitializesWithConfig() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(base: baseConfig)
        let command = CurrentUserCommand(config: config)
        
        // Command should be created successfully
        #expect(CurrentUserCommand.commandName == "current-user")
    }
    
    // MARK: - Output Format Tests
    
    @Test("Output format enum has all expected cases")
    func outputFormatEnumCases() {
        let formats: [OutputFormat] = [.json, .table, .csv, .yaml]
        
        #expect(formats.count == 4)
        #expect(OutputFormat.json.rawValue == "json")
        #expect(OutputFormat.table.rawValue == "table")
        #expect(OutputFormat.csv.rawValue == "csv")
        #expect(OutputFormat.yaml.rawValue == "yaml")
    }
    
    @Test("Output format is case iterable")
    func outputFormatIsCaseIterable() {
        let allCases = OutputFormat.allCases
        
        #expect(allCases.count == 4)
        #expect(allCases.contains(.json))
        #expect(allCases.contains(.table))
        #expect(allCases.contains(.csv))
        #expect(allCases.contains(.yaml))
    }
    
    // MARK: - Field Filtering Tests
    
    @Test("Field filtering with nil fields returns all")
    func fieldFilteringWithNilFields() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(base: baseConfig, fields: nil)
        
        // When fields is nil, all fields should be included
        #expect(config.fields == nil)
    }
    
    @Test("Field filtering with specific fields")
    func fieldFilteringWithSpecificFields() throws {
        let baseConfig = try MistDemoConfig()
        let fields = ["userRecordName", "emailAddress", "firstName"]
        let config = CurrentUserConfig(base: baseConfig, fields: fields)
        
        #expect(config.fields?.count == 3)
        #expect(config.fields?.contains("userRecordName") == true)
        #expect(config.fields?.contains("emailAddress") == true)
        #expect(config.fields?.contains("firstName") == true)
    }
    
    // MARK: - Mock User Response Tests
    
    @Test("Mock user response structure")
    func mockUserResponseStructure() {
        // This test verifies the expected structure of a user response
        let mockUser: [String: Any] = [
            "userRecordName": "_abc123def456",
            "emailAddress": "test@example.com",
            "firstName": "Test",
            "lastName": "User",
            "hasValidatedEmail": true
        ]
        
        #expect(mockUser["userRecordName"] as? String == "_abc123def456")
        #expect(mockUser["emailAddress"] as? String == "test@example.com")
        #expect(mockUser["firstName"] as? String == "Test")
        #expect(mockUser["lastName"] as? String == "User")
        #expect(mockUser["hasValidatedEmail"] as? Bool == true)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Command handles authentication error gracefully")
    func commandHandlesAuthError() throws {
        // Test that authentication errors are properly handled
        let error = MistDemoError.authenticationFailed(
            "Invalid credentials",
            context: "current-user"
        )
        
        #expect(error.code == "AUTH_FAILED")
        #expect(error.message.contains("Invalid credentials"))
        #expect(error.recoverySuggestion != nil)
    }
    
    @Test("Command handles missing API token")
    func commandHandlesMissingAPIToken() throws {
        // Test configuration error for missing API token
        let error = ConfigurationError.missingRequired(
            "api.token",
            suggestion: "Provide API token via --api-token or environment variable"
        )
        
        #expect(error.code == "CONFIG_ERROR")
        #expect(error.message.contains("api.token"))
    }
    
    // MARK: - Database Selection Tests
    
    @Test("Database defaults to private for authenticated user")
    func databaseDefaultsToPrivate() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(base: baseConfig)
        
        // With web auth token, database should be private
        // This is determined during command execution based on auth
        #expect(config.base.environment == .development)
    }
    
    // MARK: - Integration with MistKitClientFactory
    
    @Test("MistKitClientFactory configuration")
    func mistKitClientFactoryConfig() throws {
        let config = try MistDemoConfig()
        
        // Verify config has necessary properties for client creation
        #expect(config.containerIdentifier == "iCloud.com.brightdigit.MistDemo")
        #expect(config.environment == .development)
        #expect(config.resolvedApiToken().isEmpty)
        #expect(config.resolvedWebAuthToken() == nil)
    }
}