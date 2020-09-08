import Foundation

extension JSONEncoder: MKEncoder {
  func data<EncodableType: MKEncodable>(from object: EncodableType) throws -> Data {
    try encode(object)
  }
}
