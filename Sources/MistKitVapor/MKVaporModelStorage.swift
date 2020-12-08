import MistKit

public class MKVaporModelStorage<ModelType: MKModelStorable>: MKTokenStorage {
  public let model: ModelType

  public var webAuthenticationToken: String? {
    get {
      model[keyPath: ModelType.tokenKey].wrappedValue
    }
    set {
      model[keyPath: ModelType.tokenKey].wrappedValue = newValue
    }
  }

  public init(model: ModelType) {
    self.model = model
  }
}
