import Foundation
import MistKit
import NIO

public class MKNIOHTTP1TokenClient: MKTokenClient {
  var channel: Channel?
  let bindTo: BindTo
  let onRedirectURL: (URL) -> Void

  public init(bindTo: BindTo, onRedirectURL: ((URL) -> Void)? = nil) {
    self.bindTo = bindTo
    self.onRedirectURL = onRedirectURL ?? { print($0) }
  }

  public func request(_ request: MKAuthenticationResponse?, _ callback: @escaping ((Result<String, Error>) -> Void)) {
    if let url = request?.redirectURL {
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
