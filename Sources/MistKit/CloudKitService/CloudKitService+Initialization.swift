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
  ///
  /// ## Transport
  ///
  /// Every CloudKit Web Services request built by this service is sent through
  /// `transport` (after MistKit's authentication middleware has signed it), so
  /// the transport sees exactly what goes on the wire. Use it to:
  ///
  /// - run on a server with another HTTP client (for example
  ///   `AsyncHTTPClientTransport` from swift-openapi-async-http-client),
  /// - replay recorded responses in a consumer's own tests, or
  /// - decorate the default `URLSessionTransport` to observe requests and
  ///   responses (a request log). A decorator sees signed requests, so it must
  ///   redact the `ckAPIToken` / `ckWebAuthToken` query items and the
  ///   `X-Apple-CloudKit-*` headers before persisting anything.
  ///
  /// Asset uploads to the CDN (``uploadAssetData(_:to:using:)``) do **not**
  /// flow through `transport`; they use `URLSession` directly (see
  /// <doc:CloudKitLimitsAndPerformance>).
  ///
  /// - Parameters:
  ///   - containerIdentifier: The CloudKit container, e.g. `iCloud.com.example.App`.
  ///   - credentials: The credential sets resolved per call.
  ///   - environment: `.development` (default) or `.production`.
  ///   - transport: The `ClientTransport` every API request is sent through.
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
  ///
  /// See ``init(containerIdentifier:credentials:environment:transport:)`` for
  /// what flows through `transport` and what doesn't.
  ///
  /// - Parameters:
  ///   - containerIdentifier: The CloudKit container, e.g. `iCloud.com.example.App`.
  ///   - tokenManager: The token manager used for every operation.
  ///   - environment: `.development` (default) or `.production`.
  ///   - transport: The `ClientTransport` every API request is sent through.
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
    /// Available on platforms that support URLSession. To supply another
    /// transport, use ``init(containerIdentifier:credentials:environment:transport:)``.
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
    /// Available on platforms that support URLSession. To supply another
    /// transport, use ``init(containerIdentifier:tokenManager:environment:transport:)``.
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
