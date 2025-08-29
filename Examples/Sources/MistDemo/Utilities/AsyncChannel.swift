//
//  AsyncChannel.swift
//  MistDemo
//
//  Created by Leo Dion on 7/9/25.
//

public import Foundation

/// AsyncChannel for communication between server and main thread
actor AsyncChannel<T> {
    private var value: T?
    private var continuation: CheckedContinuation<T, Never>?
    
    func send(_ newValue: T) {
        if let continuation = continuation {
            continuation.resume(returning: newValue)
            self.continuation = nil
        } else {
            value = newValue
        }
    }
    
    func receive() async -> T {
        if let value = value {
            self.value = nil
            return value
        }
        
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
}
