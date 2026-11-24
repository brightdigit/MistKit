//
//  ExportSchemaError.swift
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

public import Foundation

/// Errors from the `export-schema` command.
public enum ExportSchemaError: Error, LocalizedError {
  /// No management token is configured.
  case missingManagementToken
  /// No team ID is configured.
  case missingTeamID

  /// A localized description of the error.
  public var errorDescription: String? {
    switch self {
    case .missingManagementToken:
      "export-schema needs a CloudKit management token."
    case .missingTeamID:
      "export-schema needs the Apple Developer team ID that owns the container."
    }
  }

  /// A localized recovery suggestion.
  public var recoverySuggestion: String? {
    switch self {
    case .missingManagementToken:
      "Create one in CloudKit Console → Settings and set CLOUDKIT_MANAGEMENT_TOKEN "
        + "(in the environment or Examples/MistDemo/.env)."
    case .missingTeamID:
      "Set CLOUDKIT_TEAM_ID or pass --team-id (Membership tab of the Apple Developer site)."
    }
  }
}
