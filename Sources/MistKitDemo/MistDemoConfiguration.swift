import MistKit

public protocol MistDemoConfiguration {
  //  @Option()
  var apiKey: String { get }
  //
  //  @Option()
  var container: String { get }
  //
  //  @Option()
  var environment: MKEnvironment { get }

  var token: String? { get }
}

public struct MistDemoDefaultConfiguration: MistDemoConfiguration {
  public init(apiKey: String) {
    self.apiKey = apiKey
  }

  public let apiKey: String

  public let container = "iCloud.com.brightdigit.MistDemo"

  public let environment = MKEnvironment.development

  public let token: String? = nil
}
