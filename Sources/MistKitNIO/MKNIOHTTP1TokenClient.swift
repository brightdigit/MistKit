import Foundation
import MistKit
import NIO

public class MKNIOHTTP1TokenClient: MKTokenClient {
  public var channel: Channel?
  public let bindTo: BindTo
  public let onRedirectURL: (URL) -> Void

  public init(bindTo: BindTo, onRedirectURL: ((URL) -> Void)? = nil) {
    self.bindTo = bindTo
    self.onRedirectURL = onRedirectURL ?? { print($0) }
  }

  public func request(_ request: MKAuthenticationRedirect?, _ callback: @escaping ((Result<String, Error>) -> Void)) {
    if let url = request?.url {
      onRedirectURL(url)
    }
    do {
      channel = try HTTPHandler.startServer(
        htdocs: "",
        allowHalfClosure: true,
        bindTarget: bindTo
      ) { _, token in
        let actual: Result<String, Error>
        actual = .success(token)
        callback(actual)

        if let channel = self.channel {
          _ = channel.close()
        }
      }
    } catch {
      callback(.failure(error))
    }
  }
}
