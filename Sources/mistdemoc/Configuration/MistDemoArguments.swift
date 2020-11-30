import ArgumentParser
import MistKit
import MistKitDemo

struct MistDemoArguments: MistDemoConfiguration, ParsableArguments {
  @Option()
  var apiKey = "c2b958e56ab5a41aa25d673f479bbac1379f1247d83199ccd94e38bb6ae715e2"

  @Option()
  var container = "iCloud.com.brightdigit.MistDemo"

  @Option()
  var environment = MKEnvironment.development

  @Option()
  var token: String?
}

extension MKDatabase where HttpClient == MKURLSessionClient {
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
