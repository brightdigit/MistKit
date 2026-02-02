//
//  OutputFormatting+Users.swift
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

// MARK: - UserInfo Output Formatting

extension OutputFormatting {
    /// Output UserInfo result in table format
    func outputUserTable(_ userInfo: UserInfo, fields: [String]? = nil) async throws {
        print("User Information:")
        print("├─ User Record Name: \(userInfo.userRecordName)")
        
        if shouldIncludeUserField("firstName", fields: fields), let firstName = userInfo.firstName {
            print("├─ First Name: \(firstName)")
        }
        
        if shouldIncludeUserField("lastName", fields: fields), let lastName = userInfo.lastName {
            print("├─ Last Name: \(lastName)")
        }
        
        if shouldIncludeUserField("emailAddress", fields: fields), let email = userInfo.emailAddress {
            print("└─ Email: \(email)")
        } else {
            // Adjust the last character if email is not shown
            print("") // Just end the tree properly
        }
    }
    
    /// Output UserInfo results in CSV format
    func outputUserCSV(_ users: [UserInfo], fields: [String]? = nil) async throws {
        // Build header based on available fields
        var headers: [String] = ["userRecordName"]
        
        if shouldIncludeUserField("firstName", fields: fields) {
            headers.append("firstName")
        }
        if shouldIncludeUserField("lastName", fields: fields) {
            headers.append("lastName")
        }
        if shouldIncludeUserField("emailAddress", fields: fields) {
            headers.append("emailAddress")
        }
        
        print(headers.joined(separator: ","))
        
        // Output user data
        let csvEscaper = CSVEscaper()
        for user in users {
            var values: [String] = [csvEscaper.escape(user.userRecordName)]

            if shouldIncludeUserField("firstName", fields: fields) {
                values.append(csvEscaper.escape(user.firstName ?? ""))
            }
            if shouldIncludeUserField("lastName", fields: fields) {
                values.append(csvEscaper.escape(user.lastName ?? ""))
            }
            if shouldIncludeUserField("emailAddress", fields: fields) {
                values.append(csvEscaper.escape(user.emailAddress ?? ""))
            }

            print(values.joined(separator: ","))
        }
    }
    
    /// Output UserInfo result in YAML format
    func outputUserYAML(_ userInfo: UserInfo, fields: [String]? = nil) async throws {
        let yamlEscaper = YAMLEscaper()
        print("user:")
        print("  userRecordName: \(yamlEscaper.escape(userInfo.userRecordName))")

        if shouldIncludeUserField("firstName", fields: fields), let firstName = userInfo.firstName {
            print("  firstName: \(yamlEscaper.escape(firstName))")
        }

        if shouldIncludeUserField("lastName", fields: fields), let lastName = userInfo.lastName {
            print("  lastName: \(yamlEscaper.escape(lastName))")
        }

        if shouldIncludeUserField("emailAddress", fields: fields), let email = userInfo.emailAddress {
            print("  emailAddress: \(yamlEscaper.escape(email))")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if a user field should be included based on field filter
    private func shouldIncludeUserField(_ fieldName: String, fields: [String]?) -> Bool {
        guard let fields = fields, !fields.isEmpty else {
            return true // Include all fields if no filter specified
        }
        
        return fields.contains { requestedField in
            fieldName.lowercased() == requestedField.lowercased()
        }
    }
}