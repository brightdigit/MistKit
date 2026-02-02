//
//  AsyncChannelTests.swift
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

@Suite("AsyncChannel Tests")
struct AsyncChannelTests {

    // MARK: - Basic Send/Receive Tests

    @Test("Send then receive a value")
    func sendThenReceive() async {
        let channel = AsyncChannel<String>()

        await channel.send("test")
        let received = await channel.receive()

        #expect(received == "test")
    }

    @Test("Receive waits for send")
    func receiveWaitsForSend() async {
        let channel = AsyncChannel<Int>()

        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            await channel.send(42)
        }

        let received = await channel.receive()
        #expect(received == 42)
    }

    @Test("Send stores value for later receive")
    func sendStoresValue() async {
        let channel = AsyncChannel<String>()

        await channel.send("stored")

        // Delay before receiving
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        let received = await channel.receive()
        #expect(received == "stored")
    }

    // MARK: - Multiple Operations Tests

    @Test("Multiple send and receive operations")
    func multipleSendReceive() async {
        let channel = AsyncChannel<Int>()

        await channel.send(1)
        let first = await channel.receive()
        #expect(first == 1)

        await channel.send(2)
        let second = await channel.receive()
        #expect(second == 2)

        await channel.send(3)
        let third = await channel.receive()
        #expect(third == 3)
    }

    @Test("Sequential receive operations")
    func sequentialReceives() async {
        let channel = AsyncChannel<String>()

        Task {
            try? await Task.sleep(nanoseconds: 50_000_000)
            await channel.send("first")
        }

        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            await channel.send("second")
        }

        let first = await channel.receive()
        #expect(first == "first")

        let second = await channel.receive()
        #expect(second == "second")
    }

    // MARK: - Concurrent Access Tests

    @Test("Concurrent sends are handled correctly")
    func concurrentSends() async {
        let channel = AsyncChannel<Int>()

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await channel.send(1)
            }
            group.addTask {
                await channel.send(2)
            }
            group.addTask {
                await channel.send(3)
            }
        }

        // All values were sent, now receive them
        let first = await channel.receive()
        #expect([1, 2, 3].contains(first))
    }

    @Test("Concurrent receives wait for sends")
    func concurrentReceives() async {
        let channel = AsyncChannel<String>()

        let task1 = Task {
            await channel.receive()
        }

        let task2 = Task {
            await channel.receive()
        }

        try? await Task.sleep(nanoseconds: 50_000_000)

        await channel.send("value1")
        await channel.send("value2")

        let result1 = await task1.value
        let result2 = await task2.value

        #expect([result1, result2].contains("value1"))
        #expect([result1, result2].contains("value2"))
    }

    // MARK: - Type Tests

    @Test("Channel works with String type")
    func stringChannel() async {
        let channel = AsyncChannel<String>()
        await channel.send("hello")
        let received = await channel.receive()
        #expect(received == "hello")
    }

    @Test("Channel works with Int type")
    func intChannel() async {
        let channel = AsyncChannel<Int>()
        await channel.send(100)
        let received = await channel.receive()
        #expect(received == 100)
    }

    @Test("Channel works with custom Sendable type")
    func customTypeChannel() async {
        struct TestData: Sendable, Equatable {
            let id: Int
            let name: String
        }

        let channel = AsyncChannel<TestData>()
        let data = TestData(id: 1, name: "test")

        await channel.send(data)
        let received = await channel.receive()

        #expect(received == data)
    }

    @Test("Channel works with optional type")
    func optionalChannel() async {
        let channel = AsyncChannel<String?>()

        await channel.send(nil)
        let received = await channel.receive()
        #expect(received == nil)

        await channel.send("value")
        let received2 = await channel.receive()
        #expect(received2 == "value")
    }

    // MARK: - Behavior Tests

    @Test("Channel clears value after receive")
    func channelClearsValue() async {
        let channel = AsyncChannel<Int>()

        await channel.send(1)
        _ = await channel.receive()

        // Next receive should wait for new send
        Task {
            try? await Task.sleep(nanoseconds: 50_000_000)
            await channel.send(2)
        }

        let received = await channel.receive()
        #expect(received == 2)
    }

    @Test("Send replaces continuation with value delivery")
    func sendResumesContinuation() async {
        let channel = AsyncChannel<Bool>()

        let receiveTask = Task {
            await channel.receive()
        }

        try? await Task.sleep(nanoseconds: 50_000_000)
        await channel.send(true)

        let received = await receiveTask.value
        #expect(received == true)
    }

    // MARK: - Actor Isolation Tests

    @Test("Channel is isolated actor")
    func channelIsActor() async {
        let channel = AsyncChannel<String>()

        // This test verifies that AsyncChannel is an actor by using it
        // in concurrent contexts without data races
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await channel.send("message-\(i)")
                }
            }
        }

        // Receive all messages
        for _ in 0..<10 {
            _ = await channel.receive()
        }
    }

    @Test("Multiple channels are independent")
    func multipleChannelsIndependent() async {
        let channel1 = AsyncChannel<Int>()
        let channel2 = AsyncChannel<Int>()

        await channel1.send(1)
        await channel2.send(2)

        let received1 = await channel1.receive()
        let received2 = await channel2.receive()

        #expect(received1 == 1)
        #expect(received2 == 2)
    }

    // MARK: - Performance Tests

    @Test("Channel handles rapid send/receive")
    func rapidSendReceive() async {
        let channel = AsyncChannel<Int>()

        for i in 0..<100 {
            await channel.send(i)
            let received = await channel.receive()
            #expect(received == i)
        }
    }
}
