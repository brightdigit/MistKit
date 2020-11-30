import Fluent
import Vapor

public protocol MKModelStorable: Model {
  static var tokenKey: KeyPath<Self, Field<String?>> { get }
}
