import MistKit

public protocol MistDemoConfiguration {
  var apiKey: String { get }

  var container: String { get }

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
