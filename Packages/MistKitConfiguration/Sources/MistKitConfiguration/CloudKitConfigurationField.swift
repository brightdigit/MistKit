//
//  CloudKitConfigurationField.swift
//  MistKitConfiguration
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

/// A field of ``CloudKitConfiguration``, named independently of any key spelling.
///
/// Errors identify the offending field with this enum rather than a key string because
/// consuming applications spell the same field differently — CelestraCloud reads
/// `cloudkit.key-id` while another host might read `key.id` — so a string baked into the
/// package would be wrong for every consumer but one. Map a field to whatever name your
/// application presents, or to the key itself via
/// ``CloudKitConfigurationKeys/subscript(_:)``.
public enum CloudKitConfigurationField: Equatable, Sendable, CaseIterable {
  /// The CloudKit container identifier.
  case containerID
  /// The server-to-server key ID.
  case keyID
  /// The inline PEM private key.
  case privateKey
  /// The path to a PEM private key file.
  case privateKeyPath
  /// The CloudKit environment.
  case environment
}
