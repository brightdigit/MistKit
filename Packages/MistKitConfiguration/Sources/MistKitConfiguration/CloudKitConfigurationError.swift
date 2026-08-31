//
//  CloudKitConfigurationError.swift
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

/// A CloudKit configuration value that is missing or malformed.
///
/// Deliberately **not** `LocalizedError`: every consumer of this package already owns an
/// error type with its own wording, its own remediation advice, and its own key names.
/// Presenting package-authored prose to a user would contradict all three. Switch over
/// these cases and map them onto your own error instead.
///
/// ```swift
/// do {
///   let validated = try configuration.validated()
/// } catch let error as CloudKitConfigurationError {
///   throw MyError(describing: error)
/// }
/// ```
public enum CloudKitConfigurationError: Error, Equatable, Sendable {
  /// A required field was absent or empty.
  case missing(CloudKitConfigurationField)
  /// The key ID was present but malformed.
  case invalidKeyID(KeyIDValidationFailure)
  /// The inline private key was present but not well-formed PEM.
  case invalidPrivateKey(PEMValidationFailure)
  /// The environment string matched neither `development` nor `production`.
  case unrecognizedEnvironment(String)
}

extension CloudKitConfigurationError: CustomStringConvertible {
  /// A debugging description. **Not** intended for end users — map to your own error.
  public var description: String {
    switch self {
    case .missing(let field):
      return "missing(\(field))"
    case .invalidKeyID(let failure):
      return "invalidKeyID(\(failure))"
    case .invalidPrivateKey(let failure):
      return "invalidPrivateKey(\(failure))"
    case .unrecognizedEnvironment(let raw):
      return "unrecognizedEnvironment(\(raw))"
    }
  }
}
