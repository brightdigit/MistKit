import MistKit

public struct MistDemoDefaultConfiguration: MistDemoConfiguration {
  public let apiKey: String

  public let container = "iCloud.com.brightdigit.MistDemo"

  public let environment = MKEnvironment.development

  public let token: String? = nil

  public init(apiKey: String) {
    self.apiKey = apiKey
  }
}
