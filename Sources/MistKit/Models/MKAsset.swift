import Foundation

public struct MKAsset: Codable, Equatable {
  public struct URLBase: Codable, Equatable {
    let baseURL: URL

    func url(withFileName fileName: String) -> URL {
      baseURL.appendingPathComponent(fileName)
    }

    public init(from decoder: Decoder) throws {
      let baseURLString = try decoder.singleValueContainer()
      let string = try baseURLString.decode(String.self)
      guard let url = URL(
        string: string.replacingOccurrences(of: "${f}", with: "_")
      ) else {
        throw DecodingError.dataCorruptedError(
          in: baseURLString,
          debugDescription: "invalid base String"
        )
      }
      baseURL = url.deletingLastPathComponent()
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      let value = baseURL.appendingPathComponent("${f}").absoluteString
      try container.encode(value)
    }
  }

  let fileChecksum: Data
  let size: Int64
  let wrappingKey: Data
  let referenceChecksum: Data
  let downloadURL: URLBase?
  let receipt: Data?
}
