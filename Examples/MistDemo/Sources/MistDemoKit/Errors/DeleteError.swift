//
//  DeleteError.swift
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

/// Errors that can occur during delete command execution
public enum DeleteError: Error, LocalizedError {
    case recordNameRequired
    case operationFailed(String)
    case conflict(reason: String?)

    public var errorDescription: String? {
        switch self {
        case .recordNameRequired:
            return "Record name is required for delete operations. Use --record-name <name>"
        case .operationFailed(let reason):
            return "Delete operation failed: \(reason)"
        case .conflict(let reason):
            if let reason {
                return "Delete conflict: the record was modified on the server (\(reason))"
            }
            return "Delete conflict: the record was modified on the server"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .recordNameRequired:
            return "Specify a record name: mistdemo delete --record-name my-record-123"
        case .conflict:
            return "Re-run with --force to delete despite the change-tag mismatch."
        case .operationFailed:
            return nil
        }
    }
}
