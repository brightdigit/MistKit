import Foundation

public struct MKAsset: Codable, Equatable {
  let fileChecksum: Data
  let size: Int64
  let wrappingKey: Data
  let referenceChecksum: Data
  let downloadURL: URL?
  let receipt: Data?
}
