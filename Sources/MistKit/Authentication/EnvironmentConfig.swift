//
//  EnvironmentConfig.swift
//  PackageDSLKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation

/// Configuration management using environment variables for sensitive data
public enum EnvironmentConfig {
  /// Environment variable names for CloudKit configuration
  public enum Keys {
    public static let cloudKitAPIToken = "CLOUDKIT_API_TOKEN"
    public static let cloudKitWebAuthToken = "CLOUDKIT_WEB_AUTH_TOKEN"
    public static let cloudKitKeyID = "CLOUDKIT_KEY_ID"
    public static let cloudKitPrivateKey = "CLOUDKIT_PRIVATE_KEY"
    public static let cloudKitPrivateKeyFile = "CLOUDKIT_PRIVATE_KEY_FILE"
    public static let cloudKitContainerIdentifier = "CLOUDKIT_CONTAINER_IDENTIFIER"
    public static let cloudKitEnvironment = "CLOUDKIT_ENVIRONMENT"
  }

  /// Retrieves a required environment variable or throws an error
  /// - Parameters:
  ///   - key: The environment variable key
  ///   - description: Human-readable description of what this variable is for
  /// - Returns: The environment variable value
  /// - Throws: EnvironmentConfigError if the variable is not set
  public static func getRequired(_ key: String, description: String) throws -> String {
    guard let value = ProcessInfo.processInfo.environment[key], !value.isEmpty else {
      throw EnvironmentConfigError.missingRequiredVariable(key: key, description: description)
    }
    return value
  }

  /// Retrieves an optional environment variable
  /// - Parameter key: The environment variable key
  /// - Returns: The environment variable value or nil if not set
  public static func getOptional(_ key: String) -> String? {
    let value = ProcessInfo.processInfo.environment[key]
    return value?.isEmpty == false ? value : nil
  }

  /// Retrieves an environment variable with a default value
  /// - Parameters:
  ///   - key: The environment variable key
  ///   - defaultValue: The default value to use if not set
  /// - Returns: The environment variable value or the default
  public static func get(_ key: String, default defaultValue: String) -> String {
    getOptional(key) ?? defaultValue
  }

  /// Retrieves a boolean environment variable
  /// - Parameters:
  ///   - key: The environment variable key
  ///   - defaultValue: The default value to use if not set
  /// - Returns: The boolean value of the environment variable
  public static func getBool(_ key: String, default defaultValue: Bool = false) -> Bool {
    guard let value = getOptional(key) else { return defaultValue }
    return value.lowercased() == "true" || value == "1" || value.lowercased() == "yes"
  }

  /// Retrieves an integer environment variable
  /// - Parameters:
  ///   - key: The environment variable key
  ///   - defaultValue: The default value to use if not set
  /// - Returns: The integer value of the environment variable
  public static func getInt(_ key: String, default defaultValue: Int) -> Int {
    guard let value = getOptional(key),
      let intValue = Int(value)
    else { return defaultValue }
    return intValue
  }

  /// CloudKit-specific configuration helpers
  public enum CloudKit {
    /// Gets the CloudKit API token from environment variables
    /// - Throws: EnvironmentConfigError if not set
    public static func getAPIToken() throws -> String {
      try getRequired(Keys.cloudKitAPIToken, description: "CloudKit API Token")
    }

    /// Gets the CloudKit web auth token from environment variables
    /// - Returns: The web auth token or nil if not set
    public static func getWebAuthToken() -> String? {
      getOptional(Keys.cloudKitWebAuthToken)
    }

    /// Gets the CloudKit key ID from environment variables
    /// - Throws: EnvironmentConfigError if not set
    public static func getKeyID() throws -> String {
      try getRequired(Keys.cloudKitKeyID, description: "CloudKit Key ID")
    }

    /// Gets the CloudKit private key from environment variables
    /// - Throws: EnvironmentConfigError if not set
    public static func getPrivateKey() throws -> String {
      try getRequired(Keys.cloudKitPrivateKey, description: "CloudKit Private Key")
    }

    /// Gets the CloudKit private key file path from environment variables
    /// - Returns: The private key file path or nil if not set
    public static func getPrivateKeyFile() -> String? {
      getOptional(Keys.cloudKitPrivateKeyFile)
    }

    /// Gets the CloudKit container identifier from environment variables
    /// - Parameter defaultValue: The default container identifier
    /// - Returns: The container identifier
    public static func getContainerIdentifier(default defaultValue: String) -> String {
      get(Keys.cloudKitContainerIdentifier, default: defaultValue)
    }

    /// Gets the CloudKit environment from environment variables
    /// - Parameter defaultValue: The default environment
    /// - Returns: The environment (development or production)
    public static func getEnvironment(default defaultValue: String = "development") -> String {
      let value = get(Keys.cloudKitEnvironment, default: defaultValue)
      return ["development", "production"].contains(value.lowercased())
        ? value.lowercased() : defaultValue
    }

    /// Validates that all required CloudKit environment variables are set
    /// - Throws: EnvironmentConfigError if any required variables are missing
    public static func validateRequired() throws {
      _ = try getAPIToken()
      // Other variables are optional depending on authentication method
    }

    /// Returns a dictionary of all CloudKit environment variables (with sensitive data masked)
    /// - Returns: Dictionary of environment variables with sensitive values masked
    public static func getMaskedEnvironment() -> [String: String] {
      var env: [String: String] = [:]

      if let apiToken = getOptional(Keys.cloudKitAPIToken) {
        env[Keys.cloudKitAPIToken] = apiToken.maskedAPIToken
      }

      if let webAuthToken = getOptional(Keys.cloudKitWebAuthToken) {
        env[Keys.cloudKitWebAuthToken] = webAuthToken.maskedWebAuthToken
      }

      if let keyID = getOptional(Keys.cloudKitKeyID) {
        env[Keys.cloudKitKeyID] = keyID.maskedKeyID
      }

      if getOptional(Keys.cloudKitPrivateKey) != nil {
        env[Keys.cloudKitPrivateKey] = "***REDACTED***"
      }

      if let privateKeyFile = getOptional(Keys.cloudKitPrivateKeyFile) {
        env[Keys.cloudKitPrivateKeyFile] = privateKeyFile
      }

      env[Keys.cloudKitContainerIdentifier] = getContainerIdentifier(default: "not_set")
      env[Keys.cloudKitEnvironment] = getEnvironment()

      return env
    }
  }
}

/// Errors related to environment configuration
public enum EnvironmentConfigError: Error, LocalizedError {
  case missingRequiredVariable(key: String, description: String)
  case invalidValue(key: String, value: String, expectedFormat: String)

  public var errorDescription: String? {
    switch self {
    case .missingRequiredVariable(let key, let description):
      return "Missing required environment variable '\(key)': \(description)"
    case .invalidValue(let key, let value, let expectedFormat):
      return
        "Invalid value for environment variable '\(key)': '\(value)'. Expected: \(expectedFormat)"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .missingRequiredVariable(let key, let description):
      return "Set the \(key) environment variable with a valid \(description.lowercased())"
    case .invalidValue(let key, _, let expectedFormat):
      return
        "Update the \(key) environment variable to match the expected format: \(expectedFormat)"
    }
  }
}
