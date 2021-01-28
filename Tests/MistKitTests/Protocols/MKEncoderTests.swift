@testable import MistKit
import XCTest

struct MockEncoder: MKEncoder {
  public func data<EncodableType>(
    from _: EncodableType
  ) throws -> Data where EncodableType: MKEncodable {
    throw MKError.empty
  }
}

final class MKEncoderTests: XCTestCase {
  public func testOptionalData() {
    let encoder = MockEncoder()
    let actual: Data?
    do {
      actual = try encoder.optionalData(from: MKEmptyGet.value)
    } catch {
      XCTFail(error.localizedDescription)
      return
    }
    XCTAssertNil(actual)
  }
}
