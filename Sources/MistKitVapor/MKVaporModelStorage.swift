import MistKit

public class MKVaporModelStorage<ModelType: MKModelStorable>: MKTokenStorage {
  public let model: ModelType

  public init(model: ModelType) {
    self.model = model
  }

  public var webAuthenticationToken: String? {
    get {
      return model[keyPath: ModelType.tokenKey].wrappedValue
    }
    set {
      model[keyPath: ModelType.tokenKey].wrappedValue = newValue
    }
  }
}
