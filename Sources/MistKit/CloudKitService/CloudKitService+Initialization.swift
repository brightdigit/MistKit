//
//  CloudKitService+Initialization.swift
//  MistKit
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

internal import Foundation
public import OpenAPIRuntime

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

// MARK: - Credentials-based Initializer (All Platforms)

extension CloudKitService {
  /// Initialize CloudKit service with `Credentials`.
  ///
  /// Accepts any combination of `serverToServer` and `apiAuth` material. The
  /// service does **not** carry a database — every operation that supports
  /// multiple databases takes a `database:` argument at the call site, and
  /// the appropriate token manager is resolved from `credentials` per call.
  ///
  /// Provide both credential sets when a single service must serve, for
  /// example, public-database record operations via server-to-server signing
  /// **and** user-identity routes (`fetchCaller`, `lookupUsers*`) via
  /// web-auth — those are picked apart at dispatch time.
  ///
  /// Misconfiguration (no credential set covers a given call's database +
  /// user-context combination) surfaces at call time as
  /// `CloudKitError.missingCredentials`, not at construction.
  public init(
    containerIdentifier: String,
    credentials: Credentials,
    environment: Environment = .development,
    transport: any ClientTransport
  ) {
    self.containerIdentifier = containerIdentifier
    self.environment = environment
    self.credentials = credentials
    self.fixedTokenManager = nil
    self.transport = transport
  }

  /// Initialize CloudKit service with a caller-supplied `TokenManager`.
  ///
  /// The supplied manager is used for **every** dispatched operation
  /// regardless of database or whether the route requires user context.
  /// Useful for tests and bespoke auth setups where the standard
  /// `Credentials`-driven per-call selection isn't appropriate.
  public init(
    containerIdentifier: String,
    tokenManager: any TokenManager,
    environment: Environment = .development,
    transport: any ClientTransport
  ) {
    self.containerIdentifier = containerIdentifier
    self.environment = environment
    self.credentials = nil
    self.fixedTokenManager = tokenManager
    self.transport = transport
  }
}

// MARK: - URLSession Convenience Initializers (Non-WASI Platforms)

#if !os(WASI)
  internal import OpenAPIURLSession

  extension CloudKitService {
    /// Initialize CloudKit service with `Credentials` using default
    /// `URLSessionTransport`.
    ///
    /// Available on platforms that support URLSession. For WASI builds, use
    /// the generic initializer that accepts a transport parameter.
    public init(
      containerIdentifier: String,
      credentials: Credentials,
      environment: Environment = .development
    ) {
      self.init(
        containerIdentifier: containerIdentifier,
        credentials: credentials,
        environment: environment,
        transport: URLSessionTransport()
      )
    }

    /// Initialize CloudKit service with a custom `TokenManager` using default
    /// `URLSessionTransport`.
    ///
    /// Available on platforms that support URLSession. For WASI builds, use
    /// the generic initializer that accepts a transport parameter.
    public init(
      containerIdentifier: String,
      tokenManager: any TokenManager,
      environment: Environment = .development
    ) {
      self.init(
        containerIdentifier: containerIdentifier,
        tokenManager: tokenManager,
        environment: environment,
        transport: URLSessionTransport()
      )
    }
  }
#endif
