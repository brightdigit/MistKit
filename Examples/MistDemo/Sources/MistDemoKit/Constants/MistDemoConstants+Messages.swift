//
//  MistDemoConstants+Messages.swift
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

internal import Foundation

extension MistDemoConstants {
  /// User-facing messages.
  public enum Messages {
    /// Auth server starting message.
    public static let authServerStarting =
      "\u{1F680} Starting CloudKit Authentication Server"
    /// Auth server URL format string.
    public static let authServerURL =
      "\u{1F4CD} Server URL: http://%@:%d"
    /// Auth API token format string.
    public static let authApiToken =
      "\u{1F511} API Token: %@"
    /// Auth serving files format string.
    public static let authServingFiles =
      "\u{1F4C1} Serving static files from: %@"
    /// Auth opening browser message.
    public static let authOpeningBrowser =
      "\u{1F310} Opening browser..."
    /// Auth browser disabled format string.
    public static let authBrowserDisabled =
      "\u{2139}\u{FE0F}  Browser opening disabled."
      + " Navigate to http://%@:%d manually"
    /// Auth waiting message.
    public static let authWaiting =
      "\u{23F3} Waiting for authentication..."
    /// Auth timeout message.
    public static let authTimeout = "   Timeout: 5 minutes"
    /// Auth cancel message.
    public static let authCancel = "   Press Ctrl+C to cancel"
    /// Auth success message.
    public static let authSuccess =
      "\u{2705} Authentication successful! Received token."
    /// Auth success detail message.
    public static let authSuccessMessage =
      "Authentication successful! Token received."

    /// No records found message.
    public static let noRecordsFound = "No records found"
    /// Records found format string.
    public static let recordsFound = "Found %d record(s)"

    /// Record created message.
    public static let recordCreated =
      "\u{2705} Record Created Successfully"
    /// Creating record message.
    public static let creatingRecord = "Creating record..."

    /// Missing API token error.
    public static let missingAPIToken = "API token is required"
    /// Missing web auth token error.
    public static let missingWebAuthToken =
      "Web auth token is required for private/shared databases"
    /// Invalid limit error format string.
    public static let invalidLimit =
      "Invalid limit %d. Must be between %d and %d."
    /// Invalid sort format error.
    public static let invalidSortFormat = "Invalid sort format"
    /// Invalid filter format error.
    public static let invalidFilterFormat =
      "Invalid filter format"
    /// No fields provided error.
    public static let noFieldsProvided =
      "No fields provided."
      + " Use --field, --json-file, or --stdin to specify fields."
  }
}
