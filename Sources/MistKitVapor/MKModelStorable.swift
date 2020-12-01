import Fluent

public protocol MKModelStorable: Model {
  static var tokenKey: KeyPath<Self, Field<String?>> { get }
}
