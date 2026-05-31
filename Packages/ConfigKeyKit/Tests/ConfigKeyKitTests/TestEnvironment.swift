//
//  TestEnvironment.swift
//  ConfigKeyKit
//
//  Created by Leo Dion on 5/19/26.
//

internal enum TestEnvironment {
  internal static let hangsOnTestRunning: Bool = {
    #if os(Windows) && swift(<6.3)
      return true
    #else
      return false
    #endif
  }()
}
