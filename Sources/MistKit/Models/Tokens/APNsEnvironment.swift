//
//  APNsEnvironment.swift
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

/// The APNs environment a CloudKit-minted token targets.
///
/// Passed to ``CloudKitService/createAPNsToken(environment:database:)`` to mint a
/// token for either the sandbox or production Apple Push Notification service.
public enum APNsEnvironment: String, Codable, Sendable, CaseIterable {
  /// The APNs sandbox environment, paired with the CloudKit `development`
  /// container environment.
  case development
  /// The APNs production environment, paired with the CloudKit `production`
  /// container environment.
  case production
}

// MARK: - Internal Conversion
extension Operations.createToken.Input.Body.jsonPayload.apnsEnvironmentPayload {
  internal init(from environment: APNsEnvironment) {
    switch environment {
    case .development:
      self = .development
    case .production:
      self = .production
    }
  }
}
