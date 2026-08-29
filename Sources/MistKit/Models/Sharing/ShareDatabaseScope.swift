//
//  ShareDatabaseScope.swift
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

internal import MistKitOpenAPI

/// The database scope that holds a shared record, as reported by
/// `records/resolve` and `records/accept`.
///
/// Distinct from ``Database``: this is a plain descriptor CloudKit returns
/// about where the shared record lives, carrying no per-call
/// ``PublicAuthPreference``.
public enum ShareDatabaseScope: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
  /// The public database.
  case `public` = "PUBLIC"
  /// The owner's private database.
  case `private` = "PRIVATE"
  /// The caller's shared database.
  case shared = "SHARED"
}

// MARK: - Internal Conversion
extension ShareDatabaseScope {
  internal init(from payload: Components.Schemas.ShortGUIDResult.databaseScopePayload) {
    switch payload {
    case .PUBLIC: self = .public
    case .PRIVATE: self = .private
    case .SHARED: self = .shared
    }
  }
}
