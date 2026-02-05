//
//  ConfigKeySourceTests.swift
//  ConfigKeyKit
//
//  Tests for ConfigKeySource enum
//

import Testing

@testable import ConfigKeyKit

@Suite("ConfigKeySource Tests")
internal struct ConfigKeySourceTests {
  @Test("All cases")
  internal func allCases() {
    let sources = ConfigKeySource.allCases
    #expect(sources.count == 2)
    #expect(sources.contains(.commandLine))
    #expect(sources.contains(.environment))
  }
}
