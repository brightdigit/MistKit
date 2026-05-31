//
//  CommandRegistry+TestCommandTypes.swift
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

@testable import ConfigKeyKit

extension CommandRegistry {
  internal struct TestCommand: Command {
    internal typealias Config = TestConfig

    internal static var commandName: String { "test" }
    internal static var abstract: String { "Test command" }
    internal static var helpText: String { "This is a test command" }

    internal let config: TestConfig

    internal static func createInstance() async throws -> TestCommand {
      TestCommand(config: TestConfig())
    }

    internal func execute() async throws {
      // No-op for testing
    }
  }

  internal struct AnotherCommand: Command {
    internal typealias Config = TestConfig

    internal static var commandName: String { "another" }
    internal static var abstract: String { "Another command" }
    internal static var helpText: String { "This is another test command" }

    internal let config: TestConfig

    internal static func createInstance() async throws -> AnotherCommand {
      AnotherCommand(config: TestConfig())
    }

    internal func execute() async throws {
      // No-op for testing
    }
  }

  internal struct TestConfig: ConfigurationParseable {
    internal typealias ConfigReader = TestConfigReader
    internal typealias BaseConfig = Never

    internal init(configuration: TestConfigReader, base: Never? = nil) async throws {
      // No-op for testing
    }

    internal init() {
      // Simple initializer for testing
    }
  }

  internal struct TestConfigReader: Sendable {
    // Minimal config reader for testing
  }
}
