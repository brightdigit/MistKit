import Foundation

extension JSONEncoder: MKEncoder {
  public func data<EncodableType: MKEncodable>(
    from object: EncodableType
  ) throws -> Data {
    try encode(object)
  }
}
