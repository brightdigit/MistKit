import Foundation
import MistKit
import Vapor

public enum MKServerResponse<Success>: Codable where Success: Codable {
  public enum CodingKeys: String, CodingKey {
    case redirectURL
    case result
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.result) {
      self = try .success(container.decode(Success.self, forKey: .result))
    } else if container.contains(.redirectURL) {
      self = try .failure(container.decode(URL.self, forKey: .redirectURL))
    } else {
      throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "No Valid Keys"))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .failure(url):
      try container.encode(url, forKey: .redirectURL)
    case let .success(data):
      try container.encode(data, forKey: .result)
    }
  }

  public init(fromResult result: Result<Success, Error>) throws {
    switch result {
    case let .success(value): self = .success(value)
    case let .failure(mkError as MKError):
      if case let MKError.authenticationRequired(redirect) = mkError {
        self = .failure(redirect.url)
      } else {
        throw mkError
      }
    case let .failure(error): throw error
    }
  }

  case failure(URL)
  case success(Success)
}

extension MKServerResponse: Content {}
