//
//  Database+Scope.swift
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

extension Database {
  /// Which database, without how a public-database request is signed.
  ///
  /// Codes as the database's path segment (`public`, `private`, `shared`),
  /// so a client can store a database choice and build the ``Database`` when
  /// it sends a request.
  public enum Scope: String, Codable, Hashable, Sendable, CaseIterable {
    /// The public database.
    case `public`
    /// The private database. Needs a web auth token.
    case `private`
    /// The shared database. Needs a web auth token.
    case shared
  }

  /// Which database this is.
  public var scope: Scope {
    switch self {
    case .public:
      .public
    case .private:
      .private
    case .shared:
      .shared
    }
  }

  /// The database for `scope`.
  ///
  /// - Parameters:
  ///   - scope: Which database.
  ///   - publicAuthentication: How public-database requests are signed;
  ///     ignored for the private and shared databases.
  public init(_ scope: Scope, publicAuthentication: PublicAuthPreference) {
    switch scope {
    case .public:
      self = .public(publicAuthentication)
    case .private:
      self = .private
    case .shared:
      self = .shared
    }
  }
}
