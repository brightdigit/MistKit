import Foundation
public protocol MKEncoder {
  func data<EncodableType: MKEncodable>(from object: EncodableType) throws -> Data
}

public extension MKEncoder {
  func optionalData<EncodableType: MKEncodable>(from object: EncodableType) throws -> Data? {
    guard !(object is MKEmptyGet) else {
      return nil
    }

    return try data(from: object)
  }
}
