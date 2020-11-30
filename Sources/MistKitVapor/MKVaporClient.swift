import MistKit
import Vapor

public struct MKVaporClient: MKHttpClient {
  public let client: Client

  public init(client: Client) {
    self.client = client
  }

  public func request(withURL url: URL, data: Data?) -> MKVaporClientRequest {
    var clientRequest = ClientRequest()
    clientRequest.url = URI(string: url.absoluteString)
    if let data = data {
      clientRequest.body = ByteBuffer(data: data)
      clientRequest.method = .POST
      clientRequest.headers.add(name: .contentType, value: "application/json")
    }
    return MKVaporClientRequest(client: client, request: clientRequest)
  }
}
