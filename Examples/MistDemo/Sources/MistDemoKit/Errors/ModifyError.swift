//
//  ModifyError.swift
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

/// Errors that can occur during modify command execution
public enum ModifyError: Error, LocalizedError {
  case operationsRequired
  case operationsFileError(String, String)
  case emptyStdin
  case stdinError(String)
  case invalidOperationType(String)
  case missingRecordName(opIndex: Int, operation: String)
  case operationFailed(String)

  /// A localized description of the error.
  public var errorDescription: String? {
    switch self {
    case .operationsRequired:
      return
        "No operations provided."
        + " Use --operations-file <path> or pipe JSON to stdin."
    case .operationsFileError(let path, let reason):
      return
        "Failed to read operations file '\(path)': \(reason)"
    case .emptyStdin:
      return "Empty stdin. Provide a JSON array of operations."
    case .stdinError(let reason):
      return
        "Failed to parse operations from stdin: \(reason)"
    case .invalidOperationType(let opType):
      return
        "Unknown operation type '\(opType)'."
        + " Use one of: create, update, delete."
    case .missingRecordName(let index, let operation):
      return
        "Operation #\(index) (\(operation))"
        + " is missing required 'recordName'."
    case .operationFailed(let reason):
      return "Modify operation failed: \(reason)"
    }
  }

  /// A localized recovery suggestion.
  /// A localized recovery suggestion.
  public var recoverySuggestion: String? {
    switch self {
    case .operationsRequired:
      return "Provide a JSON array: --operations-file ops.json or echo '[...]' | mistdemo modify"
    case .operationsFileError:
      return "Ensure the file exists and contains a JSON array of operations."
    case .emptyStdin:
      return
        "Pipe JSON: echo"
        + " '[{\"op\":\"create\",\"recordType\":\"Note\","
        + "\"fields\":{\"title\":\"x\"}}]'"
        + " | mistdemo modify"
    case .stdinError:
      return "Check the JSON syntax of the piped input."
    case .invalidOperationType:
      return "Set 'op' to 'create', 'update', or 'delete'."
    case .missingRecordName:
      return "Update and delete operations require a 'recordName'. Create may omit it."
    case .operationFailed:
      return nil
    }
  }
}
