//
//  OutputEscaperFactoryTests.swift
//  MistDemoTests
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

@Suite("OutputEscaperFactory Tests")
struct OutputEscaperFactoryTests {
    // MARK: - Factory Method Tests

    @Test("Factory returns CSVEscaper for CSV format")
    func csvFormatReturnsCsvEscaper() {
        let escaper = OutputEscaperFactory.escaper(for: .csv)
        #expect(escaper is CSVEscaper)
    }

    @Test("Factory returns YAMLEscaper for YAML format")
    func yamlFormatReturnsYamlEscaper() {
        let escaper = OutputEscaperFactory.escaper(for: .yaml)
        #expect(escaper is YAMLEscaper)
    }

    @Test("Factory returns JSONEscaper for JSON format")
    func jsonFormatReturnsJsonEscaper() {
        let escaper = OutputEscaperFactory.escaper(for: .json)
        #expect(escaper is JSONEscaper)
    }

    @Test("Factory returns TableEscaper for table format")
    func tableFormatReturnsTableEscaper() {
        let escaper = OutputEscaperFactory.escaper(for: .table)
        #expect(escaper is TableEscaper)
    }

    // MARK: - Functional Verification Tests

    @Test("CSV escaper handles commas correctly")
    func csvEscaperHandlesCommas() {
        let escaper = OutputEscaperFactory.escaper(for: .csv)
        let result = escaper.escape("a,b,c")
        #expect(result == "\"a,b,c\"")
    }

    @Test("YAML escaper handles reserved words correctly")
    func yamlEscaperHandlesReservedWords() {
        let escaper = OutputEscaperFactory.escaper(for: .yaml)
        let result = escaper.escape("yes")
        #expect(result == "\"yes\"")
    }

    @Test("JSON escaper handles quotes correctly")
    func jsonEscaperHandlesQuotes() {
        let escaper = OutputEscaperFactory.escaper(for: .json)
        let result = escaper.escape("test\"value")
        #expect(result.contains("\\\""))
    }

    @Test("Table escaper handles newlines correctly")
    func tableEscaperHandlesNewlines() {
        let escaper = OutputEscaperFactory.escaper(for: .table)
        let result = escaper.escape("line1\nline2")
        #expect(result == "line1 line2")
    }

    // MARK: - All Format Coverage Tests

    @Test("Factory covers all OutputFormat cases")
    func factoryCoversAllFormats() {
        let allFormats = OutputFormat.allCases
        #expect(allFormats.count == 4)

        for format in allFormats {
            let escaper = OutputEscaperFactory.escaper(for: format)
            // Verify each escaper is created successfully
            let testString = "test"
            let _ = escaper.escape(testString)
        }
    }

    @Test("Each format produces different escaper instance types")
    func eachFormatProducesDifferentType() {
        let csvEscaper = OutputEscaperFactory.escaper(for: .csv)
        let yamlEscaper = OutputEscaperFactory.escaper(for: .yaml)
        let jsonEscaper = OutputEscaperFactory.escaper(for: .json)
        let tableEscaper = OutputEscaperFactory.escaper(for: .table)

        #expect(type(of: csvEscaper) != type(of: yamlEscaper))
        #expect(type(of: csvEscaper) != type(of: jsonEscaper))
        #expect(type(of: csvEscaper) != type(of: tableEscaper))
        #expect(type(of: yamlEscaper) != type(of: jsonEscaper))
        #expect(type(of: yamlEscaper) != type(of: tableEscaper))
        #expect(type(of: jsonEscaper) != type(of: tableEscaper))
    }
}
