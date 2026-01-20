//
//  IntegrationTestError.swift
//  MistDemo
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, publish, distribute, sublicense, and/or
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

/// Errors that can occur during integration testing
enum IntegrationTestError: LocalizedError, Sendable {
    case zoneNotFound(String)
    case uploadFailed(String)
    case recordCreationFailed(String)
    case syncTokenMissing
    case verificationFailed(String)
    case cleanupFailed(String)
    case noRecordsCreated

    var errorDescription: String? {
        switch self {
        case .zoneNotFound(let zone):
            return "Zone not found: \(zone)"
        case .uploadFailed(let reason):
            return "Asset upload failed: \(reason)"
        case .recordCreationFailed(let reason):
            return "Record creation failed: \(reason)"
        case .syncTokenMissing:
            return "Sync token not available from initial fetch"
        case .verificationFailed(let reason):
            return "Verification failed: \(reason)"
        case .cleanupFailed(let reason):
            return "Cleanup failed: \(reason)"
        case .noRecordsCreated:
            return "No records were successfully created"
        }
    }
}
