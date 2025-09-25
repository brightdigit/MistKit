//
//  DefaultDependencyContainer.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

/// Default implementation of dependency injection container
public final class DefaultDependencyContainer: DependencyContainer, @unchecked Sendable {
  private var factories: [String: @Sendable () throws -> Any] = [:]
  private let lock = NSLock()

  public init() {}

  public func register<T: Sendable>(_ type: T.Type, factory: @escaping @Sendable () throws -> T) {
    lock.lock()
    defer { lock.unlock() }

    let key = String(describing: type)
    factories[key] = factory
  }

  public func resolve<T: Sendable>(_ type: T.Type) throws -> T {
    lock.lock()
    defer { lock.unlock() }

    let key = String(describing: type)
    guard let factory = factories[key] else {
      throw DependencyResolutionError.notRegistered(type: key)
    }

    do {
      guard let instance = try factory() as? T else {
        throw DependencyResolutionError.resolutionFailed(
          type: key,
          underlying: DependencyResolutionError.notRegistered(type: key)
        )
      }
      return instance
    } catch {
      throw DependencyResolutionError.resolutionFailed(type: key, underlying: error)
    }
  }
}
