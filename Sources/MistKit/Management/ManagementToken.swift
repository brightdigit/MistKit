//
//  ManagementToken.swift
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

/// A CloudKit management token, which authorizes CloudKit Management API
/// calls such as schema export.
///
/// Create one in CloudKit Console under your account's Settings; the console
/// shows it once. Apple documents that a management token is "scoped to a team
/// and user", "allows access to the CloudKit management APIs", has "a default
/// lifespan of one year", and "can be revoked from the Settings section of
/// CloudKit Dashboard" ("Automating CloudKit Development",
/// developer.apple.com/icloud/cloudkit/automating/). It is not tied to one
/// container or environment.
///
/// The value never appears in `description`, `debugDescription`, string
/// interpolation or reflection (`dump`, `Mirror`), so it can't leak through
/// logs.
public struct ManagementToken: Sendable, Hashable, CustomStringConvertible,
  CustomDebugStringConvertible, CustomReflectable
{
  /// The raw token, sent in the `X-Apple-CloudKit-Management-Token` header.
  internal let value: String

  /// A redacted placeholder.
  public var description: String {
    "ManagementToken(redacted)"
  }

  /// A redacted placeholder.
  public var debugDescription: String {
    description
  }

  /// A mirror with no children, so `dump` and `Mirror` can't reach the value.
  public var customMirror: Mirror {
    Mirror(self, children: [], displayStyle: .struct)
  }

  /// Wraps a management token copied from CloudKit Console.
  public init(_ value: String) {
    self.value = value
  }
}
