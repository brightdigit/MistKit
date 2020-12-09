// swiftlint:disable:this file_name

import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public extension MKDatabase where HttpClient == MKURLSessionClient {
  init(connection: MKDatabaseConnection,
       factory: MKURLBuilderFactory? = nil,
       requestConfigFactory _: RequestConfigurationFactoryProtocol? = nil,
       tokenManager: MKTokenManagerProtocol? = nil,
       session: URLSession? = nil,
       resultSink: ResultSinkProtocol? = nil) {
    let factory = factory ?? MKURLBuilderFactory()
    urlBuilder = factory.builder(
      forConnection: connection,
      withTokenManager: tokenManager
    )
    client = MKURLSessionClient(session: session ?? URLSession.shared)
    requestConfigFactory = RequestConfigurationFactory()
    self.resultSink = resultSink ?? ResultSink()
  }
}
