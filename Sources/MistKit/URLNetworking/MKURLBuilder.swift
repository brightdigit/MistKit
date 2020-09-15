import Foundation

public class MKURLBuilder {
  public init(tokenEncoder: MKTokenEncoder?, connection: MKDatabaseConnection, tokenManager: MKTokenManagerProtocol? = nil) {
    self.tokenEncoder = tokenEncoder
    self.connection = connection
    self.tokenManager = tokenManager
  }

  public let tokenEncoder: MKTokenEncoder?
  public let connection: MKDatabaseConnection
  public let tokenManager: MKTokenManagerProtocol?

  public func url(withPathComponents pathComponents: [String]) throws -> URL {
    var url = connection.url
    for path in pathComponents {
      url.appendPathComponent(path)
    }
    let query = queryItems.map {
      [$0.key, $0.value].joined(separator: "=")
    }.joined(separator: "&")
    guard let result = URL(string: [url.absoluteString, query].joined(separator: "?")) else {
      throw MKError.invalidURLQuery(query)
    }
    return result
  }
}

extension MKURLBuilder {
  var queryItems: [String: String] {
    var parameters = ["ckAPIToken": connection.apiToken]
    if let webAuthenticationToken = tokenManager?.webAuthenticationToken, let tokenEncoder = self.tokenEncoder {
      parameters["ckWebAuthToken"] = tokenEncoder.encode(webAuthenticationToken)
      parameters["ckSession"] = tokenEncoder.encode(webAuthenticationToken)
    }
    return parameters
  }
}
