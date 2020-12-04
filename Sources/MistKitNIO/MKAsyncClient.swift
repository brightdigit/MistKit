import AsyncHTTPClient
import Foundation
import MistKit

public struct MKAsyncClient: MKHttpClient {
  public let client: HTTPClient

  public init(client: HTTPClient) {
    self.client = client
  }

  public func request(withURL url: URL, data: Data?) -> MKAsyncRequest {
    MKAsyncRequest(client: client, url: url, data: data)
  }
}
