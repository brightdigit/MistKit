//
//  ModifyZonesError.swift
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

/// Errors that can occur during modify-zones command execution.
public enum ModifyZonesError: Error, LocalizedError {
  case databaseNotSupported
  case operationsRequired
  case operationsFileError(String, String)
  case emptyStdin
  case parsingFailed(String)
  case invalidOperationType(String)
  case invalidZoneName(String)

  /// A localized description of the error.
  public var errorDescription: String? {
    switch self {
    case .databaseNotSupported:
      return
        "Zone modification requires --database private or --database shared. "
        + "CloudKit's public database has no user-modifiable zones."
    case .operationsRequired:
      return
        "No operations provided. "
        + "Use --operations-file <path> or pipe JSON to stdin."
    case .operationsFileError(let path, let reason):
      return "Failed to read operations file '\(path)': \(reason)"
    case .emptyStdin:
      return "Empty stdin. Provide a JSON object with `operations`."
    case .parsingFailed(let reason):
      return "Failed to parse zone operations: \(reason)"
    case .invalidOperationType(let opType):
      return
        "Unknown zone operation type '\(opType)'. "
        + "Use one of: create, delete."
    case .invalidZoneName(let name):
      return "Invalid zone name '\(name)'."
    }
  }

  /// A localized recovery suggestion.
  public var recoverySuggestion: String? {
    switch self {
    case .databaseNotSupported:
      return "Rerun with --database private or --database shared."
    case .operationsRequired:
      return
        "Provide JSON: --operations-file ops.json or "
        + "echo '{\"operations\":[...]}' | mistdemo modify-zones --stdin"
    case .operationsFileError:
      return "Ensure the file exists and contains valid JSON."
    case .emptyStdin:
      return
        "Pipe JSON: echo "
        + "'{\"operations\":[{\"type\":\"create\",\"zoneName\":\"X\"}]}' "
        + "| mistdemo modify-zones --stdin"
    case .parsingFailed:
      return "Check the JSON syntax and the schema of each operation."
    case .invalidOperationType:
      return "Set 'type' to 'create' or 'delete'."
    case .invalidZoneName:
      return "Provide a non-empty zone name without leading/trailing whitespace."
    }
  }
}
