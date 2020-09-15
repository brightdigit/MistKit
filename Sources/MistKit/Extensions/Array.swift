import Foundation

public extension Array where Element == UInt8 {
  internal init(uuid: UUID) {
    // swiftlint:disable:next force_cast
    self = Mirror(reflecting: uuid.uuid).children.map { $0.value as! UInt8 }
  }
}

//
// public extension Array {
//  var only: Element? {
//    guard count == 1 else {
//      return nil
//    }
//    return first
//  }
// }
