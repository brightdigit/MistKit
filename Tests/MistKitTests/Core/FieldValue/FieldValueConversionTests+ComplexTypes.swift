import Foundation
import Testing

@testable import MistKit

extension FieldValueConversionTests {
  @Suite("Complex Type Conversions")
  internal struct ComplexTypes {
    @Test("Convert location FieldValue to Components.FieldValue")
    internal func convertLocation() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let location = FieldValue.Location(
        latitude: 37.7749,
        longitude: -122.4194,
        horizontalAccuracy: 10.0,
        verticalAccuracy: 5.0,
        altitude: 100.0,
        speed: 2.5,
        course: 45.0,
        timestamp: Date(timeIntervalSince1970: 1_000_000)
      )
      let fieldValue = FieldValue.location(location)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(components.type == .location)
      if case .locationValue(let value) = components.value {
        #expect(value.latitude == 37.7749)
        #expect(value.longitude == -122.4194)
        #expect(value.horizontalAccuracy == 10.0)
        #expect(value.verticalAccuracy == 5.0)
        #expect(value.altitude == 100.0)
        #expect(value.speed == 2.5)
        #expect(value.course == 45.0)
        #expect(value.timestamp != nil)
      } else {
        Issue.record("Expected locationValue")
      }
    }

    @Test("Convert location with minimal fields to Components.FieldValue")
    internal func convertMinimalLocation() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let location = FieldValue.Location(latitude: 0.0, longitude: 0.0)
      let fieldValue = FieldValue.location(location)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(components.type == .location)
      if case .locationValue(let value) = components.value {
        #expect(value.latitude == 0.0)
        #expect(value.longitude == 0.0)
        #expect(value.horizontalAccuracy == nil)
        #expect(value.verticalAccuracy == nil)
        #expect(value.altitude == nil)
        #expect(value.speed == nil)
        #expect(value.course == nil)
        #expect(value.timestamp == nil)
      } else {
        Issue.record("Expected locationValue")
      }
    }

    @Test("Convert reference FieldValue without action to Components.FieldValue")
    internal func convertReferenceWithoutAction() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let reference = FieldValue.Reference(recordName: "test-record-123")
      let fieldValue = FieldValue.reference(reference)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(components.type == .reference)
      if case .referenceValue(let value) = components.value {
        #expect(value.recordName == "test-record-123")
        #expect(value.action == nil)
      } else {
        Issue.record("Expected referenceValue")
      }
    }

    @Test("Convert reference FieldValue with DELETE_SELF action to Components.FieldValue")
    internal func convertReferenceWithDeleteSelfAction() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let reference = FieldValue.Reference(recordName: "test-record-456", action: .deleteSelf)
      let fieldValue = FieldValue.reference(reference)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(components.type == .reference)
      if case .referenceValue(let value) = components.value {
        #expect(value.recordName == "test-record-456")
        #expect(value.action == .DELETE_SELF)
      } else {
        Issue.record("Expected referenceValue")
      }
    }

    @Test("Convert reference FieldValue with NONE action to Components.FieldValue")
    internal func convertReferenceWithNoneAction() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let reference = FieldValue.Reference(
        recordName: "test-record-789", action: FieldValue.Reference.Action.none)
      let fieldValue = FieldValue.reference(reference)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(components.type == .reference)
      if case .referenceValue(let value) = components.value {
        #expect(value.recordName == "test-record-789")
        #expect(value.action == .NONE)
      } else {
        Issue.record("Expected referenceValue")
      }
    }

    @Test("Convert asset FieldValue with all fields to Components.FieldValue")
    internal func convertAssetWithAllFields() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let asset = FieldValue.Asset(
        fileChecksum: "abc123",
        size: 1_024,
        referenceChecksum: "def456",
        wrappingKey: "key789",
        receipt: "receipt_xyz",
        downloadURL: "https://example.com/file.jpg"
      )
      let fieldValue = FieldValue.asset(asset)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(components.type == .asset)
      if case .assetValue(let value) = components.value {
        #expect(value.fileChecksum == "abc123")
        #expect(value.size == 1_024)
        #expect(value.referenceChecksum == "def456")
        #expect(value.wrappingKey == "key789")
        #expect(value.receipt == "receipt_xyz")
        #expect(value.downloadURL == "https://example.com/file.jpg")
      } else {
        Issue.record("Expected assetValue")
      }
    }

    @Test("Convert asset FieldValue with minimal fields to Components.FieldValue")
    internal func convertAssetWithMinimalFields() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let asset = FieldValue.Asset()
      let fieldValue = FieldValue.asset(asset)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(components.type == .asset)
      if case .assetValue(let value) = components.value {
        #expect(value.fileChecksum == nil)
        #expect(value.size == nil)
        #expect(value.referenceChecksum == nil)
        #expect(value.wrappingKey == nil)
        #expect(value.receipt == nil)
        #expect(value.downloadURL == nil)
      } else {
        Issue.record("Expected assetValue")
      }
    }
  }
}
