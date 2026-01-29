//
//  AuthTokenCommandTests.swift
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
import Hummingbird
import HTTPTypes
import MistKit

@testable import MistDemo

@Suite("AuthTokenCommand Tests")
struct AuthTokenCommandTests {
    // MARK: - Configuration Tests
    
    @Test("AuthTokenConfig initializes with default values")
    func authTokenConfigInitializesWithDefaults() {
        let config = AuthTokenConfig(apiToken: "test-token")
        
        #expect(config.apiToken == "test-token")
        #expect(config.port == 8080)
        #expect(config.host == "127.0.0.1")
        #expect(config.noBrowser == false)
    }
    
    @Test("AuthTokenConfig accepts custom values")
    func authTokenConfigAcceptsCustomValues() {
        let config = AuthTokenConfig(
            apiToken: "custom-token",
            port: 3000,
            host: "localhost",
            noBrowser: true
        )
        
        #expect(config.apiToken == "custom-token")
        #expect(config.port == 3000)
        #expect(config.host == "localhost")
        #expect(config.noBrowser == true)
    }
    
    // MARK: - Error Tests
    
    @Test("AuthTokenError timeout has correct description")
    func authTokenErrorTimeoutDescription() {
        let error = AuthTokenError.timeout("Operation timed out after 5 minutes")
        
        #expect(error.errorDescription == "Authentication timeout: Operation timed out after 5 minutes")
    }
    
    @Test("AuthTokenError missing resource has correct description")
    func authTokenErrorMissingResourceDescription() {
        let error = AuthTokenError.missingResource("index.html not found")
        
        #expect(error.errorDescription == "Missing resource: index.html not found")
    }
    
    @Test("AuthTokenError server error has correct description")
    func authTokenErrorServerErrorDescription() {
        let error = AuthTokenError.serverError("Failed to bind to port")
        
        #expect(error.errorDescription == "Server error: Failed to bind to port")
    }
    
    // MARK: - Mock Server Tests
    
    @Test("AuthRequest decodes correctly")
    func authRequestDecodesCorrectly() throws {
        let json = """
        {
            "sessionToken": "mock-session-token",
            "userRecordName": "user123"
        }
        """
        
        let data = Data(json.utf8)
        let request = try JSONDecoder().decode(AuthRequest.self, from: data)
        
        #expect(request.sessionToken == "mock-session-token")
        #expect(request.userRecordName == "user123")
    }
    
    @Test("AuthResponse encodes correctly")
    func authResponseEncodesCorrectly() throws {
        let response = AuthResponse(
            userRecordName: "user123",
            cloudKitData: CloudKitData(user: nil, zones: [], error: nil),
            message: "Success"
        )
        
        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        #expect(decoded.userRecordName == "user123")
        #expect(decoded.message == "Success")
        #expect(decoded.cloudKitData.zones.isEmpty)
    }
    
    // MARK: - Command Initialization Tests
    
    @Test("Command initializes with config")
    func commandInitializesWithConfig() {
        let config = AuthTokenConfig(apiToken: "test-api-token")
        let command = AuthTokenCommand(config: config)
        
        // Command should be created successfully
        #expect(AuthTokenCommand.commandName == "auth-token")
        #expect(AuthTokenCommand.abstract == "Obtain a web authentication token via browser flow")
    }
    
    // MARK: - API Token Masking Tests
    
    @Test("API token masking works correctly")
    func apiTokenMaskingWorks() {
        let shortToken = "abc"
        #expect(shortToken.maskedAPIToken == "***")
        
        let mediumToken = "abcdef"
        #expect(mediumToken.maskedAPIToken == "ab****")
        
        let longToken = "abcdefghijklmnop"
        #expect(longToken.maskedAPIToken == "ab************op")
    }
    
    // MARK: - Browser Opener Tests
    
    @Test("BrowserOpener handles different platforms")
    func browserOpenerHandlesPlatforms() {
        // This test verifies the BrowserOpener doesn't crash
        // Actual browser opening is platform-specific and can't be tested
        let url = "http://localhost:8080"
        
        // Should not throw or crash
        BrowserOpener.openBrowser(url: url)
        
        #expect(true) // If we got here, no crash occurred
    }
    
    // MARK: - AsyncChannel Tests
    
    @Test("AsyncChannel sends and receives values")
    func asyncChannelSendsAndReceives() async {
        let channel = AsyncChannel<String>()
        
        Task {
            await channel.send("test-value")
        }
        
        let value = await channel.receive()
        #expect(value == "test-value")
    }
    
    @Test("AsyncChannel handles multiple values in order")
    func asyncChannelHandlesMultipleValues() async {
        let channel = AsyncChannel<Int>()
        
        Task {
            await channel.send(1)
            await channel.send(2)
            await channel.send(3)
        }
        
        let first = await channel.receive()
        let second = await channel.receive()
        let third = await channel.receive()
        
        #expect(first == 1)
        #expect(second == 2)
        #expect(third == 3)
    }
    
    // MARK: - Timeout Tests
    
    @Test("Timeout helper throws on timeout")
    func timeoutHelperThrowsOnTimeout() async throws {
        do {
            _ = try await withTimeoutAndSignals(seconds: 0.1) {
                try await Task.sleep(nanoseconds: 1_000_000_000) // Sleep for 1 second
                return "should-not-return"
            }
            Issue.record("Should have timed out")
        } catch is AsyncTimeoutError {
            // Expected timeout error
            #expect(Bool(true))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test("Timeout helper returns value before timeout")
    func timeoutHelperReturnsValue() async throws {
        let result = try await withTimeoutAndSignals(seconds: 1.0) {
            return "success"
        }
        
        #expect(result == "success")
    }
}

// MARK: - Mock HTTP Context for Testing

// Tests for AuthTokenCommand HTTP functionality would require more complex mocking
// These tests focus on the configuration and error handling aspects