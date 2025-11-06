import Foundation

/// Represents the signing status for a build
/// Can be: array of device IDs, boolean true (all signed), or empty array (none signed)
enum SignedStatus: Codable {
    case devices([String]) // Array of signed device IDs
    case all(Bool)         // true = all devices signed
    case none              // Empty array = not signed

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try decoding as array first
        if let devices = try? container.decode([String].self) {
            if devices.isEmpty {
                self = .none
            } else {
                self = .devices(devices)
            }
        }
        // Then try boolean
        else if let allSigned = try? container.decode(Bool.self) {
            self = .all(allSigned)
        }
        // Default to none if decoding fails
        else {
            self = .none
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .devices(let devices):
            try container.encode(devices)
        case .all(let value):
            try container.encode(value)
        case .none:
            try container.encode([String]())
        }
    }

    /// Check if a specific device identifier is signed
    func isSigned(for deviceIdentifier: String) -> Bool {
        switch self {
        case .devices(let devices):
            return devices.contains(deviceIdentifier)
        case .all(true):
            return true
        case .all(false), .none:
            return false
        }
    }
}
