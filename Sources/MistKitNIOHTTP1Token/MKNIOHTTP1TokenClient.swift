import Foundation
import MistKit
import NIO

public class MKNIOHTTP1TokenClient: MKTokenClient {
  var channel: Channel?
  // public var webAuthenticationToken: String?
  public init() {}

  public func request(_ request: MKAuthenticationResponse?, _ callback: @escaping ((Result<String, Error>) -> Void)) {
    if let url = request?.redirectURL {
      print(url)
    }
    do {
      channel = try HTTPHandler.startServer(
        htdocs: "",
        allowHalfClosure: true,
        bindTarget: .ipAddress(host: "127.0.0.1", port: 7000)
      ) { _, token in
        // self.webAuthenticationToken = token

        // .whenComplete { (result) in
        let actual: Result<String, Error>
//        if let token = token {
        actual = .success(token)

//        } else {
//          actual = .failure(MKNIOHTTP1Error.noToken)
//        }

        // }

        // }
        callback(actual)
        // }
        // }

        if let channel = self.channel {
          // DispatchQueue.global().async {

          channel.close()
        }
      }

    } catch {
      callback(.failure(error))
    }
  }
}
