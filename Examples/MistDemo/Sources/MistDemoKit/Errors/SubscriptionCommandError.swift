//
//  SubscriptionCommandError.swift
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

/// Errors raised by the subscription commands before a CloudKit call is made.
public enum SubscriptionCommandError: Error, LocalizedError {
  /// No subscription IDs were supplied to a lookup command.
  case missingSubscriptionIDs
  /// No subscription ID was supplied to a modify command.
  case missingSubscriptionID
  /// A `create` operation was requested without a `--record-type`.
  case missingRecordType
  /// An unrecognized `--operation` value was supplied.
  case invalidOperation(String)

  /// A localized description of the error.
  public var errorDescription: String? {
    switch self {
    case .missingSubscriptionIDs:
      return "No subscription IDs supplied. Pass --subscription-ids <comma,separated,list>."
    case .missingSubscriptionID:
      return "No subscription ID supplied. Pass --subscription-id <id>."
    case .missingRecordType:
      return "Creating a query subscription requires --record-type <type>."
    case .invalidOperation(let value):
      return "Unknown operation '\(value)'. Use 'create' or 'delete'."
    }
  }
}
