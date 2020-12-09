#if !canImport(ObjectiveC)
  import XCTest

  extension CharacterMapEncoderTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__CharacterMapEncoderTests = [
      ("testDefaultInit", testDefaultInit),
      ("testEncode", testEncode)
    ]
  }

  extension MKTokenManagerTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__MKTokenManagerTests = [
      ("testRequest", testRequest),
      ("testWebAuthenticationToken", testWebAuthenticationToken)
    ]
  }

  extension RecordNameParserTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__RecordNameParserTests = [
      ("testUUIDs", testUUIDs)
    ]
  }

  extension RequestConfigurationFactoryTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__RequestConfigurationFactoryTests = [
      ("testConfiguration", testConfiguration)
    ]
  }

  public func __allTests() -> [XCTestCaseEntry] {
    return [
      testCase(CharacterMapEncoderTests.__allTests__CharacterMapEncoderTests),
      testCase(MKTokenManagerTests.__allTests__MKTokenManagerTests),
      testCase(RecordNameParserTests.__allTests__RecordNameParserTests),
      testCase(RequestConfigurationFactoryTests.__allTests__RequestConfigurationFactoryTests)
    ]
  }
#endif
