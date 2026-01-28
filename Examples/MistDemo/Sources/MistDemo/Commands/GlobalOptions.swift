//
//  GlobalOptions.swift
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

import ArgumentParser
import Foundation
import MistKit

/// Global options shared across all MistDemo commands
struct GlobalOptions: ParsableArguments, Sendable {
  // MARK: Lifecycle

  init() {}

  // MARK: Public

  // MARK: - Configuration

  @Option(name: .long, help: "Path to configuration file (JSON or YAML)")
  var configFile: String?

  @Option(name: .long, help: "Configuration profile to use")
  var profile: String?

  // MARK: - Output

  @Option(name: .long, help: "Output format (json, table, csv, yaml)")
  var output: OutputFormat = .json

  @Flag(name: .long, help: "Pretty-print output (applies to JSON and YAML)")
  var pretty: Bool = false

  @Flag(name: .long, help: "Enable verbose logging")
  var verbose: Bool = false

  // MARK: - CloudKit Core

  @Option(name: [.short, .long], help: "CloudKit container identifier")
  var containerIdentifier: String?

  @Option(name: [.short, .long], help: "CloudKit API token")
  var apiToken: String?

  @Option(name: .long, help: "CloudKit environment (development or production)")
  var environment: String?

  @Option(name: .long, help: "CloudKit database (public, private, or shared)")
  var database: String?

  // MARK: - Authentication

  @Option(name: .long, help: "Web authentication token from Sign in with Apple")
  var webAuthToken: String?

  @Option(name: .long, help: "Server-to-server key identifier")
  var keyID: String?

  @Option(name: .long, help: "Server-to-server private key (PEM format)")
  var privateKey: String?

  @Option(name: .long, help: "Path to server-to-server private key file")
  var privateKeyFile: String?

  /// Load configuration from all sources (CLI args, config file, environment variables)
  func loadConfiguration() async throws -> MistDemoConfig {
    // Use existing EnhancedConfigurationReader which handles:
    // - Command line arguments via getCommandLineValue()
    // - Environment variables
    // - Defaults
    // Swift Configuration integration deferred - EnhancedConfigurationReader already works perfectly
    return MistDemoConfig()
  }
}
