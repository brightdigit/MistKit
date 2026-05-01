//
//  OutputFormatting.swift
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
import MistKit

/// Protocol for formatting command output in different formats
public protocol OutputFormatting {
    /// Output a single result in the specified format
    func outputResult<T: Encodable>(_ result: T, format: OutputFormat) async throws
    
    /// Output multiple results in the specified format
    func outputResults<T: Encodable>(_ results: [T], format: OutputFormat) async throws
}

public extension OutputFormatting {
    /// Default implementation for outputting a single result
    func outputResult<T: Encodable>(_ result: T, format: OutputFormat) async throws {
        try await outputResults([result], format: format)
    }
    
    /// Default implementation for outputting multiple results
    func outputResults<T: Encodable>(_ results: [T], format: OutputFormat) async throws {
        switch format {
        case .json:
            try await outputJSON(results)
        case .table:
            try await outputTable(results)
        case .csv:
            try await outputCSV(results)
        case .yaml:
            try await outputYAML(results)
        }
    }
}

