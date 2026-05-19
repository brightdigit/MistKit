//
//  CommandRegistry+AvailableCommands.swift
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

import Testing

@testable import ConfigKeyKit

extension CommandRegistry {
  @Suite("Available Commands")
  internal struct AvailableCommands {
    @Test("Available commands lists registered commands")
    internal func availableCommands() async {
      let registry = ConfigKeyKit.CommandRegistry()

      await registry.register(CommandRegistry.TestCommand.self)
      await registry.register(CommandRegistry.AnotherCommand.self)

      let commands = await registry.availableCommands

      #expect(commands.contains("test"))
      #expect(commands.contains("another"))
      #expect(commands.count == 2)
    }

    @Test("Available commands returns empty for new registry")
    internal func availableCommandsEmpty() async {
      let registry = ConfigKeyKit.CommandRegistry()

      let commands = await registry.availableCommands

      #expect(commands.isEmpty)
    }

    @Test("Available commands are sorted")
    internal func availableCommandsSorted() async {
      let registry = ConfigKeyKit.CommandRegistry()

      await registry.register(CommandRegistry.AnotherCommand.self)
      await registry.register(CommandRegistry.TestCommand.self)

      let commands = await registry.availableCommands

      #expect(commands == ["another", "test"])
    }
  }
}
