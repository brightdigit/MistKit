import MistKit

public protocol MistDemoConfiguration {
  var apiKey: String { get }

  var container: String { get }

  var environment: MKEnvironment { get }

  var token: String? { get }
}
