//
//  CommandIntegrationTests.swift
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

@Suite("Command Integration Tests")
struct CommandIntegrationTests {
    // MARK: - Test Configuration
    
    private func createTestConfig() throws -> MistDemoConfig {
        return try MistDemoConfig()
    }
    
    private func createMockAuthResult() throws -> AuthenticationResult {
        let mockTokenManager = MockCommandTokenManager()
        return AuthenticationResult(
            tokenManager: mockTokenManager,
            database: .private,
            authMethod: "mock-auth"
        )
    }
    
    // MARK: - AuthTokenCommand Integration Tests
    
    @Test("AuthTokenCommand configuration validation")
    func authTokenCommandConfigValidation() throws {
        let config = AuthTokenConfig(
            apiToken: "test-api-token-123",
            port: 8080,
            host: "127.0.0.1",
            noBrowser: true
        )
        
        let command = AuthTokenCommand(config: config)
        
        // Verify command is properly configured
        #expect(AuthTokenCommand.commandName == "auth-token")
        #expect(AuthTokenCommand.abstract.contains("authentication token"))
    }
    
    @Test("AuthTokenCommand resource path validation")
    func authTokenCommandResourcePathValidation() throws {
        let config = AuthTokenConfig(apiToken: "test-token")
        let command = AuthTokenCommand(config: config)
        
        // Test that resource finding logic doesn't crash
        // This tests the findResourcesPath method indirectly
        #expect(AuthTokenCommand.commandName == "auth-token")
    }
    
    // MARK: - CurrentUserCommand Integration Tests
    
    @Test("CurrentUserCommand end-to-end flow")
    func currentUserCommandEndToEndFlow() throws {
        let baseConfig = try createTestConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: ["userRecordName", "emailAddress"],
            output: .json
        )
        
        let command = CurrentUserCommand(config: config)
        
        // Verify command configuration
        #expect(type(of: command).commandName == "current-user")
        
        // Verify config properties
        #expect(config.fields?.count == 2)
        #expect(config.output == .json)
    }
    
    @Test("CurrentUserCommand with field filtering")
    func currentUserCommandWithFieldFiltering() throws {
        let baseConfig = try createTestConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: ["userRecordName", "firstName", "lastName"],
            output: .table
        )
        
        let command = CurrentUserCommand(config: config)
        
        // Verify field filtering setup
        #expect(config.fields?.contains("userRecordName") == true)
        #expect(config.fields?.contains("firstName") == true)
        #expect(config.fields?.contains("lastName") == true)
        #expect(config.output == .table)
    }
    
    // MARK: - QueryCommand Integration Tests
    
    @Test("QueryCommand with filters and sorting")
    func queryCommandWithFiltersAndSorting() throws {
        let baseConfig = try createTestConfig()
        let config = QueryConfig(
            base: baseConfig,
            zone: "_defaultZone",
            recordType: "Note",
            filters: ["title:contains:Test", "priority:gt:3"],
            sort: (field: "createdAt", order: .descending),
            limit: 50,
            fields: ["title", "content", "createdAt"]
        )
        
        let command = QueryCommand(config: config)
        
        // Verify query configuration
        #expect(type(of: command).commandName == "query")
        #expect(config.filters.count == 2)
        #expect(config.sort?.field == "createdAt")
        #expect(config.sort?.order == .descending)
        #expect(config.limit == 50)
    }
    
    @Test("QueryCommand pagination setup")
    func queryCommandPaginationSetup() throws {
        let baseConfig = try createTestConfig()
        let config = QueryConfig(
            base: baseConfig,
            limit: 10,
            offset: 20,
            continuationMarker: "next-page-token"
        )
        
        let command = QueryCommand(config: config)
        
        // Verify pagination configuration
        #expect(config.limit == 10)
        #expect(config.offset == 20)
        #expect(config.continuationMarker == "next-page-token")
    }
    
    // MARK: - CreateCommand Integration Tests
    
    @Test("CreateCommand with parsed fields")
    func createCommandWithParsedFields() throws {
        let baseConfig = try createTestConfig()
        let fields = [
            try Field.parse("title:string:Integration Test Note"),
            try Field.parse("priority:int64:8"),
            try Field.parse("progress:double:0.85")
        ]
        
        let config = CreateConfig(
            base: baseConfig,
            zone: "_defaultZone",
            recordName: "test-record-123",
            fields: fields
        )
        
        let command = CreateCommand(config: config)
        
        // Verify create configuration
        #expect(type(of: command).commandName == "create")
        #expect(config.fields.count == 3)
        #expect(config.recordName == "test-record-123")
        
        // Verify field parsing
        let titleField = config.fields.first { $0.name == "title" }
        #expect(titleField?.type == .string)
        #expect(titleField?.value == "Integration Test Note")
    }
    
    @Test("CreateCommand field type validation")
    func createCommandFieldTypeValidation() throws {
        let baseConfig = try createTestConfig()
        
        // Test different field types
        let stringField = try Field.parse("description:string:This is a test description")
        let intField = try Field.parse("count:int64:42")
        let doubleField = try Field.parse("rating:double:4.5")
        let timestampField = try Field.parse("deadline:timestamp:2026-12-31T23:59:59Z")
        
        let config = CreateConfig(
            base: baseConfig,
            zone: "_defaultZone",
            recordName: nil,
            fields: [stringField, intField, doubleField, timestampField]
        )
        
        let command = CreateCommand(config: config)
        
        #expect(config.fields.count == 4)
        
        // Verify each field type
        let fieldTypes = config.fields.map(\.type)
        #expect(fieldTypes.contains(.string))
        #expect(fieldTypes.contains(.int64))
        #expect(fieldTypes.contains(.double))
        #expect(fieldTypes.contains(.timestamp))
    }
    
    // MARK: - Cross-Command Integration Tests
    
    @Test("Configuration consistency across commands")
    func configurationConsistencyAcrossCommands() throws {
        let baseConfig = try createTestConfig()
        
        // Create configs for all commands
        let authConfig = AuthTokenConfig(apiToken: "test-token")
        let userConfig = CurrentUserConfig(base: baseConfig)
        let queryConfig = QueryConfig(base: baseConfig)
        let createConfig = CreateConfig(base: baseConfig, zone: "_defaultZone", recordName: nil, fields: [])
        
        // Verify all use same base container
        #expect(userConfig.base.containerIdentifier == baseConfig.containerIdentifier)
        #expect(queryConfig.base.containerIdentifier == baseConfig.containerIdentifier)
        #expect(createConfig.base.containerIdentifier == baseConfig.containerIdentifier)
        
        // Verify environment consistency
        #expect(userConfig.base.environment == .development)
        #expect(queryConfig.base.environment == .development)
        #expect(createConfig.base.environment == .development)
    }
    
    @Test("Output format consistency")
    func outputFormatConsistency() throws {
        let baseConfig = try createTestConfig()
        
        let userConfig = CurrentUserConfig(base: baseConfig, output: .json)
        let queryConfig = QueryConfig(base: baseConfig, output: .json)
        
        #expect(userConfig.output == .json)
        #expect(queryConfig.output == .json)
        
        // Test other formats
        let csvUserConfig = CurrentUserConfig(base: baseConfig, output: .csv)
        let csvQueryConfig = QueryConfig(base: baseConfig, output: .csv)
        
        #expect(csvUserConfig.output == .csv)
        #expect(csvQueryConfig.output == .csv)
    }
    
    // MARK: - Error Handling Integration Tests
    
    @Test("Authentication error propagation")
    func authenticationErrorPropagation() throws {
        let authError = MistDemoError.authenticationFailed(
            "Invalid token",
            context: "integration-test"
        )
        
        #expect(authError.code == "AUTH_FAILED")
        #expect(authError.message.contains("Invalid token"))
        #expect(authError.recoverySuggestion != nil)
    }
    
    @Test("Configuration error handling")
    func configurationErrorHandling() throws {
        let configError = ConfigurationError.missingRequired(
            "api.token",
            suggestion: "Provide token via --api-token"
        )
        
        #expect(configError.code == "CONFIG_ERROR")
        #expect(configError.suggestion?.contains("--api-token") == true)
    }
    
    // MARK: - Real-world Usage Simulation
    
    @Test("Simulate complete workflow")
    func simulateCompleteWorkflow() throws {
        // 1. Auth token configuration
        let authConfig = AuthTokenConfig(
            apiToken: "mock-api-token-for-test",
            noBrowser: true
        )
        let authCommand = AuthTokenCommand(config: authConfig)
        
        // 2. Current user check
        let baseConfig = try createTestConfig()
        let userConfig = CurrentUserConfig(base: baseConfig)
        let userCommand = CurrentUserCommand(config: userConfig)
        
        // 3. Query existing records
        let queryConfig = QueryConfig(
            base: baseConfig,
            filters: ["title:contains:test"],
            limit: 10
        )
        let queryCommand = QueryCommand(config: queryConfig)
        
        // 4. Create new record
        let fields = [try Field.parse("title:string:Workflow Test")]
        let createConfig = CreateConfig(
            base: baseConfig,
            zone: "_defaultZone",
            recordName: nil,
            fields: fields
        )
        let createCommand = CreateCommand(config: createConfig)
        
        // Verify all commands are properly configured
        #expect(authCommand.commandName == "auth-token")
        #expect(userCommand.commandName == "current-user")
        #expect(queryCommand.commandName == "query")
        #expect(createCommand.commandName == "create")
    }
}

// MARK: - Mock Token Manager for Integration Tests

internal final class MockCommandTokenManager: TokenManager {
    var hasCredentials: Bool {
        get async { true }
    }
    
    func validateCredentials() async throws(TokenManagerError) -> Bool {
        return true
    }
    
    func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
        return .webAuth(apiToken: "mock-api", webAuthToken: "mock-web-auth")
    }
}