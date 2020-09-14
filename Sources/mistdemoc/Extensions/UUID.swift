import ArgumentParser
import Foundation

extension UUID: ExpressibleByArgument {
  public init?(argument: String) {
    guard let uuid = UUID(uuidString: argument) else {
      return nil
    }
    self = uuid
  }
}
