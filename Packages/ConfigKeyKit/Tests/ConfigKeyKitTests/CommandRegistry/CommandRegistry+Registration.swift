//
//  CommandRegistry+Registration.swift
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
  @Suite("Registration")
  internal struct Registration {
    @Test("Register a command")
    internal func registerCommand() async {
      let registry = ConfigKeyKit.CommandRegistry()

      await registry.register(CommandRegistry.TestCommand.self)

      let isRegistered = await registry.isRegistered("test")
      #expect(isRegistered == true)
    }

    @Test("Register multiple commands")
    internal func registerMultipleCommands() async {
      let registry = ConfigKeyKit.CommandRegistry()

      await registry.register(CommandRegistry.TestCommand.self)
      await registry.register(CommandRegistry.AnotherCommand.self)

      let testRegistered = await registry.isRegistered("test")
      let anotherRegistered = await registry.isRegistered("another")

      #expect(testRegistered == true)
      #expect(anotherRegistered == true)
    }

    @Test("Unregistered command returns false")
    internal func unregisteredCommand() async {
      let registry = ConfigKeyKit.CommandRegistry()

      let isRegistered = await registry.isRegistered("nonexistent")
      #expect(isRegistered == false)
    }
  }
}
