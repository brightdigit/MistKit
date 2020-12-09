@testable import MistKit
import XCTest



public extension String {
  static func random(ofLength length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{_ in 
      return letters.randomElement()!
    })
  }
}
final class CharacterMapEncoderTests: XCTestCase {
  func testDefaultInit () {
    let encoder = CharacterMapEncoder()
    XCTAssertEqual(encoder.characterMap, ["+": "%2B", "/": "%2F", "=": "%3D"])
  }
  
  fileprivate func encodingTest() {
    var map = [String : String]()
    var token = ""
    var expected = ""
    var characters = Set<String>()
    repeat {
      characters.formUnion([String.random(ofLength: 1)])
    } while (characters.count < 8)
    
    repeat {
      guard let key  = characters.popFirst(), let value = characters.popFirst() else {
        break
      }
      map[key] = value
      token += key + value
      expected += value + value
      token += key + value
      expected += value + value
    } while !characters.isEmpty
    let encoder = CharacterMapEncoder(characterMap: map)
    let actual = encoder.encode(token)
    XCTAssertEqual(actual, expected)
  }
  
  func testEncode () {
    for _ in (0..<100) {
      encodingTest()
    }
  }
}
