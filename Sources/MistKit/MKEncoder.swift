import Foundation
protocol MKEncoder {
  func data<EncodableType: MKEncodable>(from object: EncodableType) throws -> Data
}

extension MKEncoder {
  func optionalData<EncodableType: MKEncodable>(from object: EncodableType) throws -> Data? {
    guard !(object is MKEmptyGet) else {
      return nil
    }

    return try data(from: object)
  }
}
