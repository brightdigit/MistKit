//
//  QueryError.swift
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

import Foundation

/// Errors specific to query command
public enum QueryError: Error, LocalizedError {
    case invalidLimit(Int)
    case invalidFilter(String, expected: String)
    case emptyFieldName(String)
    case invalidSortOrder(String, available: [String])
    case unsupportedOperator(String)
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidLimit(let limit):
            return String(format: MistDemoConstants.Messages.invalidLimit, limit, MistDemoConstants.Limits.minQueryLimit, MistDemoConstants.Limits.maxQueryLimit)
        case .invalidFilter(let filter, let expected):
            return "Invalid filter '\(filter)'. Expected format: \(expected)"
        case .emptyFieldName(let filter):
            return "Empty field name in filter '\(filter)'"
        case .invalidSortOrder(let order, let available):
            return "Invalid sort order '\(order)'. Available orders: \(available.joined(separator: ", "))"
        case .unsupportedOperator(let op):
            return "Unsupported filter operator '\(op)'. Supported: eq, ne, gt, gte, lt, lte, contains, begins_with, in, not_in"
        case .operationFailed(let message):
            return "Query operation failed: \(message)"
        }
    }
}
