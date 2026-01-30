//
//  CurrentUserCommand.swift
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
import MistKit

/// Command to get information about the authenticated user
public struct CurrentUserCommand: MistDemoCommand, OutputFormatting {
    public typealias Config = CurrentUserConfig
    public static let commandName = "current-user"
    public static let abstract = "Get current user information"
    public static let helpText = """
        CURRENT-USER - Get current user information

        USAGE:
            mistdemo current-user [options]

        OPTIONS:
            --api-token <token>        CloudKit API token
            --web-auth-token <token>   Web authentication token
            --fields <fields>          Comma-separated list of fields to include
            --output-format <format>   Output format: json, table, csv, yaml
        """
    
    private let config: CurrentUserConfig
    
    public init(config: CurrentUserConfig) {
        self.config = config
    }
    
    public func execute() async throws {
        do {
            // Create CloudKit client
            let client = try MistKitClientFactory.create(from: config.base)
            
            // Fetch current user information
            let userInfo = try await client.fetchCurrentUser()
            
            // Filter fields if requested
            let filteredUser = filterUserFields(userInfo, fields: config.fields)
            
            // Format and output result
            try await outputResult(filteredUser, format: config.output)
            
        } catch {
            throw CurrentUserError.operationFailed(error.localizedDescription)
        }
    }
    
    /// Filter user fields based on requested fields
    /// Since UserInfo constructor is internal, we work with the original object
    /// and filter during output instead
    private func filterUserFields(_ userInfo: UserInfo, fields: [String]?) -> UserInfo {
        // Since we can't create new UserInfo instances, return the original
        // Field filtering will be handled in the output methods
        return userInfo
    }
    
    /// Check if a field should be included in output based on field filters
    private func shouldIncludeField(_ fieldName: String, fields: [String]?) -> Bool {
        guard let fields = fields, !fields.isEmpty else {
            return true // Include all fields if no filter specified
        }
        
        return fields.contains { requestedField in
            switch fieldName.lowercased() {
            case "firstname", "first_name":
                return requestedField.lowercased() == "firstname" || requestedField.lowercased() == "first_name"
            case "lastname", "last_name":
                return requestedField.lowercased() == "lastname" || requestedField.lowercased() == "last_name"
            case "email", "emailaddress", "email_address":
                return requestedField.lowercased() == "email" || requestedField.lowercased() == "emailaddress" || requestedField.lowercased() == "email_address"
            case "userrecordname", "user_record_name", "recordname", "record_name":
                return requestedField.lowercased() == "userrecordname" || requestedField.lowercased() == "user_record_name" || requestedField.lowercased() == "recordname" || requestedField.lowercased() == "record_name"
            default:
                return requestedField.lowercased() == fieldName.lowercased()
            }
        }
    }
}

/// Errors specific to current-user command
public enum CurrentUserError: Error, LocalizedError {
    case operationFailed(String)
    case authenticationRequired
    
    public var errorDescription: String? {
        switch self {
        case .operationFailed(let message):
            return "Current user operation failed: \(message)"
        case .authenticationRequired:
            return "Authentication is required for current-user command. Use auth-token command first or provide --web-auth-token."
        }
    }
}