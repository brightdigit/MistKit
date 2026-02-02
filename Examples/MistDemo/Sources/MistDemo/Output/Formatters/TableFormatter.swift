//
//  TableFormatter.swift
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

/// Formatter for table output
public struct TableFormatter: OutputFormatter {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func format<T: Encodable>(_ value: T) throws -> String {
        // For table format, we need to handle specific types
        // since table formatting is inherently structure-dependent
        if let recordInfo = value as? RecordInfo {
            return try formatRecord(recordInfo)
        } else if let userInfo = value as? UserInfo {
            return try formatUser(userInfo)
        } else {
            // Fall back to JSON for unknown types
            let jsonFormatter = JSONFormatter(pretty: true)
            return try jsonFormatter.format(value)
        }
    }

    // MARK: Private

    private func formatRecord(_ record: RecordInfo) throws -> String {
        let escaper = TableEscaper()
        var output = ""

        output += "Record Name: \(escaper.escape(record.recordName))\n"
        output += "Record Type: \(escaper.escape(record.recordType))\n"

        if !record.fields.isEmpty {
            output += "Fields:\n"
            for (fieldName, fieldValue) in record.fields.sorted(by: { $0.key < $1.key }) {
                let valueString = escaper.escape(String(describing: fieldValue))
                output += "  \(fieldName): \(valueString)\n"
            }
        }

        return output
    }

    private func formatUser(_ user: UserInfo) throws -> String {
        let escaper = TableEscaper()
        var output = ""

        output += "User Record Name: \(escaper.escape(user.userRecordName))\n"

        if let firstName = user.firstName {
            output += "First Name: \(escaper.escape(firstName))\n"
        }
        if let lastName = user.lastName {
            output += "Last Name: \(escaper.escape(lastName))\n"
        }
        if let emailAddress = user.emailAddress {
            output += "Email: \(escaper.escape(emailAddress))\n"
        }

        return output
    }
}
