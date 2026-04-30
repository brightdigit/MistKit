//
//  UploadAssetError.swift
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

/// Errors that can occur during asset upload operations
public enum UploadAssetError: Error, LocalizedError {
    case filePathRequired
    case recordTypeRequired
    case fieldNameRequired
    case fileNotFound(String)
    case fileTooLarge(Int64, maximum: Int64)
    case invalidRecordType(String)
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .filePathRequired:
            return "File path is required. Usage: mistdemo upload-asset --file <path> --record-type <type> --field-name <field>"
        case .recordTypeRequired:
            return "Record type is required. Specify with --record-type <type>"
        case .fieldNameRequired:
            return "Field name is required. Specify with --field-name <field>"
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .fileTooLarge(let size, let maximum):
            let sizeMB = Double(size) / 1024 / 1024
            let maxMB = Double(maximum) / 1024 / 1024
            return "File size (\(String(format: "%.2f", sizeMB)) MB) exceeds maximum (\(String(format: "%.2f", maxMB)) MB)"
        case .invalidRecordType(let type):
            return "Invalid record type: \(type)"
        case .operationFailed(let message):
            return "Upload operation failed: \(message)"
        }
    }
}
