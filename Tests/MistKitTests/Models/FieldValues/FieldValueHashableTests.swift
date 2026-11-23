internal import Foundation
internal import Testing

@testable import MistKit

@Suite("Field Value Hashable")
/// Hashing agrees with `==` for record value types, so they work in sets and
/// as dictionary keys (brightdigit/MistKit#501).
internal struct FieldValueHashableTests {
  /// Pairs of values that are equal and must hash alike.
  private static let equalPairs: [(FieldValue, FieldValue)] = [
    (.double(.value(0.0)), .double(.value(-0.0))),
    (.double(.value(1.5)), .double(.value(1.5))),
    (.double(.list([0.0, 2.5])), .double(.list([-0.0, 2.5]))),
    (.string(.list([])), .string(.list([]))),
    (.int64(.list([1, 2, 3])), .int64(.list([1, 2, 3]))),
    (
      .location(.value(Location(latitude: 1, longitude: 2, altitude: nil))),
      .location(.value(Location(latitude: 1, longitude: 2)))
    ),
    (
      .reference(.value(Reference(recordName: "a", zoneID: nil, action: nil))),
      .reference(.value(Reference(recordName: "a")))
    ),
    (.asset(.value(Asset(size: 3))), .asset(.value(Asset(size: 3)))),
  ]

  /// Pairs of values that are not equal.
  private static let unequalPairs: [(FieldValue, FieldValue)] = [
    (.double(.value(1)), .int64(.value(1))),
    (.string(.value("a")), .string(.list(["a"]))),
    (.string(.list([])), .int64(.list([]))),
    (.double(.list([1, 2])), .double(.list([2, 1]))),
    (
      .reference(.value(Reference(recordName: "a", action: nil))),
      .reference(.value(Reference(recordName: "a", action: Reference.Action.none)))
    ),
    (
      .location(.value(Location(latitude: 1, longitude: 2, altitude: nil))),
      .location(.value(Location(latitude: 1, longitude: 2, altitude: 0)))
    ),
  ]

  @Test("Equal field values hash alike", arguments: equalPairs)
  internal func equalValuesHashAlike(lhs: FieldValue, rhs: FieldValue) {
    #expect(lhs == rhs)
    #expect(lhs.hashValue == rhs.hashValue)
    #expect(Set([lhs, rhs]).count == 1)
  }

  @Test("Unequal field values stay distinct in a set", arguments: unequalPairs)
  internal func unequalValuesStayDistinct(lhs: FieldValue, rhs: FieldValue) {
    #expect(lhs != rhs)
    #expect(Set([lhs, rhs]).count == 2)
  }

  @Test("NaN is never equal to itself, so sets keep each NaN")
  internal func nanIsNotEqual() {
    let lhs = FieldValue.double(.value(.nan))
    let rhs = FieldValue.double(.value(.nan))
    #expect(lhs != rhs)
    #expect(Set([lhs, rhs]).count == 2)
  }

  @Test("Optional fields hash consistently with ==")
  internal func optionalFieldsHashConsistently() {
    let some: FieldValue? = .string(.value("x"))
    let none: FieldValue? = nil
    let nested: FieldValue?? = .some(nil)
    #expect(Set([some, some, none, none]).count == 2)
    #expect(Set<FieldValue??>([nested, .some(nil), .none]).count == 2)
  }

  @Test("Arity is Hashable when its element is")
  internal func arityHashable() {
    let lhs = FieldValue.Arity<Double>.list([0.0])
    let rhs = FieldValue.Arity<Double>.list([-0.0])
    #expect(lhs == rhs)
    #expect(lhs.hashValue == rhs.hashValue)
  }
}
