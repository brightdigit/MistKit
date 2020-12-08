import MistKit
import Vapor

public struct MKVaporClientRequest: MKHttpRequest {
  public let client: Client
  public let request: ClientRequest

  public func execute(_ callback: @escaping ((Result<MKHttpResponse, Error>) -> Void)) {
    client.send(request).map(MKVaporClientResponse.init).whenComplete(callback)
  }
}
