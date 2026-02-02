//
//  CSVFormatter.swift
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
import MistKit

/// Formatter for CSV output
public struct CSVFormatter: OutputFormatter {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func format<T: Encodable>(_ value: T) throws -> String {
        let escaper = CSVEscaper()

        // For CSV format, we need to handle specific types
        if let recordInfo = value as? RecordInfo {
            return formatRecord(recordInfo, escaper: escaper)
        } else if let userInfo = value as? UserInfo {
            return formatUser(userInfo, escaper: escaper)
        } else {
            // Fall back to JSON for unknown types
            let jsonFormatter = JSONFormatter(pretty: false)
            return try jsonFormatter.format(value)
        }
    }

    // MARK: Private

    private func formatRecord(_ record: RecordInfo, escaper: CSVEscaper) -> String {
        var output = ""

        // Header
        output += "Field,Value\n"

        // Basic fields
        output += "recordName,\(escaper.escape(record.recordName))\n"
        output += "recordType,\(escaper.escape(record.recordType))\n"

        // Custom fields
        for (fieldName, fieldValue) in record.fields.sorted(by: { $0.key < $1.key }) {
            let valueString = String(describing: fieldValue)
            output += "\(escaper.escape(fieldName)),\(escaper.escape(valueString))\n"
        }

        return output
    }

    private func formatUser(_ user: UserInfo, escaper: CSVEscaper) -> String {
        var output = ""

        // Header
        output += "Field,Value\n"

        // User fields
        output += "userRecordName,\(escaper.escape(user.userRecordName))\n"

        if let firstName = user.firstName {
            output += "firstName,\(escaper.escape(firstName))\n"
        }
        if let lastName = user.lastName {
            output += "lastName,\(escaper.escape(lastName))\n"
        }
        if let emailAddress = user.emailAddress {
            output += "emailAddress,\(escaper.escape(emailAddress))\n"
        }

        return output
    }
}
