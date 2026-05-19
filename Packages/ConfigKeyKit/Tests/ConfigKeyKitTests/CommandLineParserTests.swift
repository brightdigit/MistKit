//
//  CommandLineParserTests.swift
//  ConfigKeyKit
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

internal import Testing

@testable import ConfigKeyKit

@Suite("CommandLineParser Tests")
internal struct CommandLineParserTests {
  @Test("parseCommandName returns nil when only executable name is present")
  internal func noArgsReturnsNil() {
    let parser = CommandLineParser(arguments: ["mytool"])

    #expect(parser.parseCommandName() == nil)
    #expect(parser.commandArguments().isEmpty)
    #expect(parser.isHelpRequested() == false)
  }

  @Test("parseCommandName returns the first non-option argument")
  internal func parsesCommand() {
    let parser = CommandLineParser(arguments: ["mytool", "query", "--limit", "10"])

    #expect(parser.parseCommandName() == "query")
    #expect(parser.commandArguments() == ["--limit", "10"])
  }

  @Test("parseCommandName returns nil when first argument is a global option")
  internal func globalOptionReturnsNilCommand() {
    let parser = CommandLineParser(arguments: ["mytool", "--config-file", "/tmp/x.json"])

    #expect(parser.parseCommandName() == nil)
    #expect(parser.commandArguments() == ["--config-file", "/tmp/x.json"])
  }

  @Test("commandArguments strips the executable + command but keeps the rest verbatim")
  internal func commandArgumentsPreserveRest() {
    let parser = CommandLineParser(arguments: ["mytool", "lookup", "rec-1", "rec-2"])

    #expect(parser.commandArguments() == ["rec-1", "rec-2"])
  }

  @Test(
    "isHelpRequested matches every documented help token",
    arguments: ["--help", "-h", "help"]
  )
  internal func helpTokens(token: String) {
    let parser = CommandLineParser(arguments: ["mytool", "query", token])

    #expect(parser.isHelpRequested() == true)
  }
}
