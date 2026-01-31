//
//  CommandRegistryTests.swift
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
@testable import ConfigKeyKit

@Suite("CommandRegistry Tests")
struct CommandRegistryTests {

    // MARK: - Test Command Types

    struct TestCommand: Command {
        typealias Config = TestConfig

        static var commandName: String { "test" }
        static var abstract: String { "Test command" }
        static var helpText: String { "This is a test command" }

        let config: TestConfig

        init(config: TestConfig) {
            self.config = config
        }

        func execute() async throws {
            // No-op for testing
        }

        static func createInstance() async throws -> TestCommand {
            return TestCommand(config: TestConfig())
        }
    }

    struct AnotherCommand: Command {
        typealias Config = TestConfig

        static var commandName: String { "another" }
        static var abstract: String { "Another command" }
        static var helpText: String { "This is another test command" }

        let config: TestConfig

        init(config: TestConfig) {
            self.config = config
        }

        func execute() async throws {
            // No-op for testing
        }

        static func createInstance() async throws -> AnotherCommand {
            return AnotherCommand(config: TestConfig())
        }
    }

    struct TestConfig: ConfigurationParseable {
        typealias ConfigReader = TestConfigReader
        typealias BaseConfig = Never

        init(configuration: TestConfigReader, base: Never? = nil) async throws {
            // No-op for testing
        }

        init() {
            // Simple initializer for testing
        }
    }

    struct TestConfigReader {
        // Minimal config reader for testing
    }

    // MARK: - Registration Tests

    @Test("Register a command")
    func registerCommand() async {
        let registry = CommandRegistry()

        await registry.register(TestCommand.self)

        let isRegistered = await registry.isRegistered("test")
        #expect(isRegistered == true)
    }

    @Test("Register multiple commands")
    func registerMultipleCommands() async {
        let registry = CommandRegistry()

        await registry.register(TestCommand.self)
        await registry.register(AnotherCommand.self)

        let testRegistered = await registry.isRegistered("test")
        let anotherRegistered = await registry.isRegistered("another")

        #expect(testRegistered == true)
        #expect(anotherRegistered == true)
    }

    @Test("Unregistered command returns false")
    func unregisteredCommand() async {
        let registry = CommandRegistry()

        let isRegistered = await registry.isRegistered("nonexistent")
        #expect(isRegistered == false)
    }

    // MARK: - Available Commands Tests

    @Test("Available commands lists registered commands")
    func availableCommands() async {
        let registry = CommandRegistry()

        await registry.register(TestCommand.self)
        await registry.register(AnotherCommand.self)

        let commands = await registry.availableCommands

        #expect(commands.contains("test"))
        #expect(commands.contains("another"))
        #expect(commands.count == 2)
    }

    @Test("Available commands returns empty for new registry")
    func availableCommandsEmpty() async {
        let registry = CommandRegistry()

        let commands = await registry.availableCommands

        #expect(commands.isEmpty)
    }

    @Test("Available commands are sorted")
    func availableCommandsSorted() async {
        let registry = CommandRegistry()

        await registry.register(AnotherCommand.self)
        await registry.register(TestCommand.self)

        let commands = await registry.availableCommands

        #expect(commands == ["another", "test"])
    }

    // MARK: - Metadata Tests

    @Test("Get command metadata")
    func getCommandMetadata() async {
        let registry = CommandRegistry()

        await registry.register(TestCommand.self)

        let metadata = await registry.metadata(for: "test")

        #expect(metadata != nil)
        #expect(metadata?.commandName == "test")
        #expect(metadata?.abstract == "Test command")
        #expect(metadata?.helpText == "This is a test command")
    }

    @Test("Get metadata for unregistered command")
    func getMetadataForUnregistered() async {
        let registry = CommandRegistry()

        let metadata = await registry.metadata(for: "nonexistent")

        #expect(metadata == nil)
    }

    // MARK: - Command Type Retrieval Tests

    @Test("Get command type by name")
    func getCommandType() async {
        let registry = CommandRegistry()

        await registry.register(TestCommand.self)

        let commandType = await registry.commandType(named: "test")

        #expect(commandType != nil)
    }

    @Test("Get command type for unregistered command")
    func getCommandTypeUnregistered() async {
        let registry = CommandRegistry()

        let commandType = await registry.commandType(named: "nonexistent")

        #expect(commandType == nil)
    }

    // MARK: - Command Creation Tests

    @Test("Create command instance")
    func createCommandInstance() async throws {
        let registry = CommandRegistry()

        await registry.register(TestCommand.self)

        let command = try await registry.createCommand(named: "test")

        #expect(command is TestCommand)
    }

    @Test("Create command instance throws for unknown command")
    func createCommandInstanceThrows() async {
        let registry = CommandRegistry()

        await #expect(throws: CommandRegistryError.self) {
            try await registry.createCommand(named: "unknown")
        }
    }

    // MARK: - Error Tests

    @Test("Unknown command error has description")
    func unknownCommandError() {
        let error = CommandRegistryError.unknownCommand("missing")
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.contains("Unknown command") == true)
        #expect(description?.contains("missing") == true)
    }

    @Test("CommandRegistryError conforms to LocalizedError")
    func errorConformsToLocalizedError() {
        let error: any Error = CommandRegistryError.unknownCommand("test")
        #expect(error is LocalizedError)
    }

    // MARK: - Concurrent Access Tests

    @Test("Concurrent registration")
    func concurrentRegistration() async {
        let registry = CommandRegistry()

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await registry.register(TestCommand.self)
            }
            group.addTask {
                await registry.register(AnotherCommand.self)
            }
        }

        let commands = await registry.availableCommands
        #expect(commands.count == 2)
    }

    @Test("Concurrent reads")
    func concurrentReads() async {
        let registry = CommandRegistry()

        await registry.register(TestCommand.self)

        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await registry.isRegistered("test")
                }
            }

            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }

            #expect(results.allSatisfy { $0 == true })
        }
    }

    @Test("Mixed concurrent operations")
    func mixedConcurrentOperations() async {
        let registry = CommandRegistry()

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await registry.register(TestCommand.self)
            }
            group.addTask {
                _ = await registry.isRegistered("test")
            }
            group.addTask {
                _ = await registry.availableCommands
            }
        }

        let isRegistered = await registry.isRegistered("test")
        #expect(isRegistered == true)
    }

    // MARK: - Overwrite Tests

    @Test("Registering same command twice overwrites")
    func registerCommandTwiceOverwrites() async {
        let registry = CommandRegistry()

        await registry.register(TestCommand.self)
        await registry.register(TestCommand.self)

        let commands = await registry.availableCommands
        #expect(commands.count == 1)
        #expect(commands.contains("test"))
    }
}
