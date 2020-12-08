import ArgumentParser
import MistKit
import MistKitDemo

public struct MistDemoArguments: MistDemoConfiguration, ParsableArguments {
  @Option()
  public var apiKey = "c2b958e56ab5a41aa25d673f479bbac1379f1247d83199ccd94e38bb6ae715e2"

  @Option()
  public var container = "iCloud.com.brightdigit.MistDemo"

  @Option()
  public var environment = MKEnvironment.development

  @Option()
  public var token: String?

  public init() {}
}

public extension MKDatabase where HttpClient == MKURLSessionClient {
  init(options: MistDemoArguments, tokenManager: MKTokenManagerProtocol) {
    // setup your connection to CloudKit
    let connection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

    // use the webAuthenticationToken which is passed
    if let token = options.token {
      tokenManager.webAuthenticationToken = token
    }

    self.init(
      connection: connection,
      tokenManager: tokenManager
    )
  }
}
