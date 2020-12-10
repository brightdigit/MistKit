import AsyncHTTPClient
import Foundation
import MistKit

public struct MKAsyncClient: MKHttpClient {
  public let client: HTTPClient

  public init(client: HTTPClient) {
    self.client = client
  }

  public func request(
    fromConfiguration configuration: RequestConfiguration
  ) -> MKAsyncRequest {
    MKAsyncRequest(client: client, url: configuration.url, data: configuration.data)
  }
}
