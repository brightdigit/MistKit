//
//  FieldParsingErrorTests.swift
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
import Testing
@testable import MistDemo

@Suite("FieldParsingError LocalizedError Tests")
struct FieldParsingErrorTests {

    // MARK: - invalidFormat Error Tests

    @Test("invalidFormat error has correct description")
    func invalidFormatErrorDescription() {
        let error = FieldParsingError.invalidFormat("title:string", expected: "name:type:value")
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.contains("Invalid field format") == true)
        #expect(description?.contains("title:string") == true)
        #expect(description?.contains("name:type:value") == true)
    }

    @Test("invalidFormat error is thrown for missing parts")
    func invalidFormatErrorThrown() {
        do {
            _ = try Field(parsing: "incomplete")
            Issue.record("Expected invalidFormat error to be thrown")
        } catch let error as FieldParsingError {
            if case .invalidFormat = error {
                // Success
            } else {
                Issue.record("Expected invalidFormat error, got \(error)")
            }
        } catch {
            Issue.record("Expected FieldParsingError, got \(error)")
        }
    }

    // MARK: - emptyFieldName Error Tests

    @Test("emptyFieldName error has correct description")
    func emptyFieldNameErrorDescription() {
        let error = FieldParsingError.emptyFieldName(":string:value")
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.contains("Empty field name") == true)
        #expect(description?.contains(":string:value") == true)
    }

    @Test("emptyFieldName error is thrown for empty name")
    func emptyFieldNameErrorThrown() {
        do {
            _ = try Field(parsing: ":string:value")
            Issue.record("Expected emptyFieldName error to be thrown")
        } catch let error as FieldParsingError {
            if case .emptyFieldName = error {
                // Success
            } else {
                Issue.record("Expected emptyFieldName error, got \(error)")
            }
        } catch {
            Issue.record("Expected FieldParsingError, got \(error)")
        }
    }

    @Test("emptyFieldName error is thrown for whitespace-only name")
    func emptyFieldNameErrorThrownForWhitespace() {
        do {
            _ = try Field(parsing: "   :string:value")
            Issue.record("Expected emptyFieldName error to be thrown")
        } catch let error as FieldParsingError {
            if case .emptyFieldName = error {
                // Success
            } else {
                Issue.record("Expected emptyFieldName error, got \(error)")
            }
        } catch {
            Issue.record("Expected FieldParsingError, got \(error)")
        }
    }

    // MARK: - unknownFieldType Error Tests

    @Test("unknownFieldType error has correct description")
    func unknownFieldTypeErrorDescription() {
        let error = FieldParsingError.unknownFieldType("invalid", available: ["string", "int64"])
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.contains("Unknown field type") == true)
        #expect(description?.contains("invalid") == true)
        #expect(description?.contains("string") == true)
        #expect(description?.contains("int64") == true)
    }

    @Test("unknownFieldType error is thrown for invalid type")
    func unknownFieldTypeErrorThrown() {
        do {
            _ = try Field(parsing: "name:invalid:value")
            Issue.record("Expected unknownFieldType error to be thrown")
        } catch let error as FieldParsingError {
            if case .unknownFieldType = error {
                // Success
            } else {
                Issue.record("Expected unknownFieldType error, got \(error)")
            }
        } catch {
            Issue.record("Expected FieldParsingError, got \(error)")
        }
    }

    // MARK: - invalidValueForType Error Tests

    @Test("invalidValueForType error has correct description for int64")
    func invalidValueForTypeInt64ErrorDescription() {
        let error = FieldParsingError.invalidValueForType("not-a-number", type: .int64)
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.contains("Invalid value") == true)
        #expect(description?.contains("not-a-number") == true)
        #expect(description?.contains("int64") == true)
    }

    @Test("invalidValueForType error has correct description for double")
    func invalidValueForTypeDoubleErrorDescription() {
        let error = FieldParsingError.invalidValueForType("not-a-number", type: .double)
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.contains("Invalid value") == true)
        #expect(description?.contains("not-a-number") == true)
        #expect(description?.contains("double") == true)
    }

    @Test("invalidValueForType error is thrown for invalid int64")
    func invalidValueForTypeInt64ErrorThrown() {
        do {
            _ = try FieldType.int64.convertValue("not-a-number")
            Issue.record("Expected invalidValueForType error to be thrown")
        } catch let error as FieldParsingError {
            if case .invalidValueForType = error {
                // Success
            } else {
                Issue.record("Expected invalidValueForType error, got \(error)")
            }
        } catch {
            Issue.record("Expected FieldParsingError, got \(error)")
        }
    }

    @Test("invalidValueForType error is thrown for invalid double")
    func invalidValueForTypeDoubleErrorThrown() {
        do {
            _ = try FieldType.double.convertValue("not-a-number")
            Issue.record("Expected invalidValueForType error to be thrown")
        } catch let error as FieldParsingError {
            if case .invalidValueForType = error {
                // Success
            } else {
                Issue.record("Expected invalidValueForType error, got \(error)")
            }
        } catch {
            Issue.record("Expected FieldParsingError, got \(error)")
        }
    }

    // MARK: - unsupportedFieldType Error Tests

    @Test("unsupportedFieldType error has correct description for asset")
    func unsupportedFieldTypeAssetErrorDescription() {
        let error = FieldParsingError.unsupportedFieldType(.asset)
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.contains("not yet supported") == true)
        #expect(description?.contains("asset") == true)
    }

    @Test("unsupportedFieldType error has correct description for location")
    func unsupportedFieldTypeLocationErrorDescription() {
        let error = FieldParsingError.unsupportedFieldType(.location)
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.contains("not yet supported") == true)
        #expect(description?.contains("location") == true)
    }

    @Test("unsupportedFieldType error is thrown for asset type")
    func unsupportedFieldTypeAssetErrorThrown() {
        do {
            _ = try FieldType.asset.convertValue("anything")
            Issue.record("Expected unsupportedFieldType error to be thrown")
        } catch let error as FieldParsingError {
            if case .unsupportedFieldType = error {
                // Success
            } else {
                Issue.record("Expected unsupportedFieldType error, got \(error)")
            }
        } catch {
            Issue.record("Expected FieldParsingError, got \(error)")
        }
    }

    @Test("unsupportedFieldType error is thrown for bytes type")
    func unsupportedFieldTypeBytesErrorThrown() {
        do {
            _ = try FieldType.bytes.convertValue("anything")
            Issue.record("Expected unsupportedFieldType error to be thrown")
        } catch let error as FieldParsingError {
            if case .unsupportedFieldType = error {
                // Success
            } else {
                Issue.record("Expected unsupportedFieldType error, got \(error)")
            }
        } catch {
            Issue.record("Expected FieldParsingError, got \(error)")
        }
    }
}
