//
//  DatabaseConfiguration.swift
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

import Foundation
import MistKit

/// A validated database + authentication pair, ready to construct a
/// `CloudKitService`.
///
/// Database (`MistKit.Database`) and authentication
/// (`AuthenticationCredentials`) are independent axes — public+S2S, public+web-auth,
/// private+web-auth, and shared+web-auth are all valid CloudKit combinations.
/// Server-to-server signing against the private/shared databases is not, so use
/// `make(database:authentication:)` to construct values; the factory rejects the
/// invalid combination and never produces a misconfigured service.
internal struct DatabaseConfiguration: Sendable {
  internal let database: MistKit.Database
  internal let authentication: AuthenticationCredentials

  /// Validate the database/authentication pairing and return a configuration.
  ///
  /// - Throws: `ConfigurationError.unsupportedDatabaseAuthCombination` for
  ///   private/shared + server-to-server, which CloudKit rejects.
  internal static func make(
    database: MistKit.Database,
    authentication: AuthenticationCredentials
  ) throws -> Self {
    switch (database, authentication) {
    case (.private, .serverToServer), (.shared, .serverToServer):
      throw ConfigurationError.unsupportedDatabaseAuthCombination(
        database: database.rawValue,
        authentication: "serverToServer"
      )
    default:
      return Self(database: database, authentication: authentication)
    }
  }
}
